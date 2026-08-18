#!/usr/bin/env python3
"""Iron Wake — Voice Casting Studio.

A local web app to pick the voice AND delivery (stability/style) of EACH
dialogue line, audition it live against ElevenLabs, and save the choice.

    python3 tools/voice_studio.py            # beach room (default prototype)
    python3 tools/voice_studio.py --all      # every room
    python3 tools/voice_studio.py --files scripts/customs_shack_room.gd

Then open the printed http://127.0.0.1:8778/ URL.

Why it works with zero game changes: the runtime finds a clip by
sha1(speaker|text), so *which* voice a line uses is decided entirely at build
time. Your picks are saved to tools/voice_overrides.json (keyed by that same
hash) and the shipping generator (generate_voiceover.py) honors them. Lines you
never touch keep today's per-character casting.

Reuses tools/generate_voiceover.py for extraction / hashing / synthesis so the
hash and rendering never drift. Previews are cached under tools/.voice_preview/
so re-listening costs nothing; only new voice+setting combos hit the API.
Nothing under assets/voice/ changes until you press Generate.
"""
import argparse
import hashlib
import json
import os
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_voiceover as gv  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
HTML_PATH = os.path.join(HERE, "voice_studio.html")
PREVIEW_DIR = os.path.join(HERE, ".voice_preview")
PORT = 8778

_write_lock = threading.Lock()


# ---- key (non-fatal, unlike gv.load_env which sys.exits) --------------------

def load_key():
    if os.path.isfile(gv.ENV_PATH):
        for raw in open(gv.ENV_PATH, encoding="utf-8"):
            raw = raw.strip()
            if not raw or raw.startswith("#") or "=" not in raw:
                continue
            k, v = raw.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    return os.environ.get("ELEVENLABS_API_KEY", "").strip()


# ---- extraction with source tagging (mirrors gv.extract_ordered) ------------

def extract_tagged(rel_files, include_responses=True):
    """(speaker, text, source_label) in true source order — same regexes/order
    as gv.extract_ordered, but tagging which file each line came from so the UI
    can group by room."""
    seq = []
    for rel in rel_files:
        path = os.path.join(gv.ROOT, rel)
        if not os.path.isfile(path):
            continue
        src = gv._strip_full_line_comments(open(path, encoding="utf-8").read())
        matches = [(m.start(), gv.NARRATION_SPEAKER, m.group(2))
                   for m in gv._RE_SAY.finditer(src)]
        matches += [(m.start(), m.group(2), m.group(4))
                    for m in gv._RE_SAY_AS.finditer(src)]
        matches += [(m.start(), m.group(3), m.group(5))
                    for m in gv._RE_ADD_NODE.finditer(src)]
        matches.sort(key=lambda x: x[0])
        label = os.path.basename(rel).replace(".gd", "")
        for _, spk, body in matches:
            text = gv.normalize(gv._unescape(body))
            if text:
                seq.append((spk, text, label))
    if include_responses:
        for rel in gv.RESPONSE_FILES:
            path = os.path.join(gv.ROOT, rel)
            if not os.path.isfile(path):
                continue
            src = open(path, encoding="utf-8").read()
            for block in gv._RE_RESPONSE_BLOCK.finditer(src):
                for sm in gv._RE_STRING.finditer(block.group(1)):
                    text = gv.normalize(gv._unescape(sm.group(2)))
                    if text:
                        seq.append((gv.NARRATION_SPEAKER, text, "verb responses"))
    return seq


def build_voices(cfg):
    """Named palette of the premade voices the project already casts, deduped by
    voice_id (a TTS-only key can use these without voices_read)."""
    notes = cfg.get("_casting_notes", {})
    id_name = {}
    for spk, vid in cfg.get("speakers", {}).items():
        if vid in id_name:
            continue
        note = notes.get(spk, "")
        name = note.split("\u2014")[0].strip() if "\u2014" in note else (note or spk)
        id_name[vid] = name or spk
    voices = [{"id": vid, "name": nm} for vid, nm in id_name.items()]
    voices.sort(key=lambda v: v["name"].lower())
    return voices


# ---- overrides persistence --------------------------------------------------

def load_overrides():
    if os.path.isfile(gv.OVERRIDES_PATH):
        try:
            data = json.load(open(gv.OVERRIDES_PATH, encoding="utf-8"))
            if isinstance(data, dict):
                return data
        except Exception:
            pass
    return {}


def save_overrides(data):
    tmp = gv.OVERRIDES_PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    os.replace(tmp, gv.OVERRIDES_PATH)


# ---- state assembly ---------------------------------------------------------

def build_state(files, cfg):
    seq_tagged = extract_tagged(files, include_responses=True)
    seq_plain = [(s, t) for (s, t, _) in seq_tagged]
    context = gv.build_context(seq_plain)
    overrides = load_overrides()

    seen = set()
    lines = []
    for spk, text, source in seq_tagged:
        key = (spk, text)
        if key in seen:
            continue
        seen.add(key)
        h = gv.line_hash(spk, text)
        ov = overrides.get(h)
        cast_vid = cfg["speakers"].get(spk, cfg["default_voice"])
        cast_settings = gv.settings_for(cfg, spk, {})
        prev, nxt = context.get(key, ("", ""))
        clip = os.path.join(gv.VOICE_DIR, h + ".mp3")
        lines.append({
            "hash": h,
            "speaker": spk,
            "source": source,
            "text": text,
            "prev": prev,
            "next": nxt,
            "cast_voice_id": cast_vid,
            "cast_settings": {
                "stability": cast_settings.get("stability"),
                "style": cast_settings.get("style"),
            },
            "override": ov,
            "clip_exists": os.path.isfile(clip),
        })
    return {
        "files": files,
        "voices": build_voices(cfg),
        "picks": sum(1 for l in lines if l["override"]),
        "have_key": bool(load_key()),
        "lines": lines,
    }


# ---- preview / generate -----------------------------------------------------

def preview_clip(cfg, body):
    """Synthesize (or reuse cached) one audition clip. Returns mp3 bytes."""
    speaker = body["speaker"]
    text = body["text"]
    voice_id = body["voice_id"]
    vs_in = body.get("voice_settings") or {}
    prev = body.get("prev", "")
    nxt = body.get("next", "")
    vs = gv.settings_for(cfg, speaker, {}, vs_in)

    os.makedirs(PREVIEW_DIR, exist_ok=True)
    key = hashlib.sha1(
        (voice_id + "|" + json.dumps(vs, sort_keys=True) + "|"
         + prev + "|" + text + "|" + nxt).encode("utf-8")
    ).hexdigest()
    cache = os.path.join(PREVIEW_DIR, key + ".mp3")
    if os.path.isfile(cache):
        return open(cache, "rb").read()

    api_key = load_key()
    if not api_key:
        raise RuntimeError("no ELEVENLABS_API_KEY (put it in tools/.env)")
    audio = gv.synth(api_key, voice_id, text, cfg, vs, prev, nxt)
    with open(cache, "wb") as f:
        f.write(audio)
    return audio


def generate_clips(cfg, items):
    """Render final shipping clips for the given [{speaker,text}] honoring picks.
    Writes assets/voice/<hash>.mp3 + updates the manifest. force=True so a
    re-pick actually replaces the old clip."""
    api_key = load_key()
    if not api_key:
        raise RuntimeError("no ELEVENLABS_API_KEY (put it in tools/.env)")
    overrides = load_overrides()
    # Context from the full default+all scope isn't needed per-item; stitching
    # uses only same-speaker neighbours, which we pass through from the client.
    results = []
    manifest = {}
    if os.path.isfile(gv.MANIFEST_PATH):
        try:
            manifest = json.load(open(gv.MANIFEST_PATH, encoding="utf-8"))
        except Exception:
            manifest = {}
    for it in items:
        spk, text = it["speaker"], it["text"]
        ctx = {(spk, text): (it.get("prev", ""), it.get("next", ""))}
        try:
            status, h, entry = gv.render_one(
                api_key, cfg, overrides, ctx, spk, text, gv.VOICE_DIR, force=True
            )
            manifest[h] = entry
            results.append({"hash": h, "status": status})
            time.sleep(0.2)
        except RuntimeError as e:
            results.append({"hash": gv.line_hash(spk, text), "status": "failed",
                            "error": str(e)})
    os.makedirs(gv.VOICE_DIR, exist_ok=True)
    with open(gv.MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    return results


# ---- HTTP -------------------------------------------------------------------

class Handler(BaseHTTPRequestHandler):
    cfg = None
    files = None

    def _send(self, code, ctype, body):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code, obj):
        self._send(code, "application/json; charset=utf-8", json.dumps(obj))

    def _body(self):
        n = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(n) or b"{}")

    def do_GET(self):
        u = urlparse(self.path)
        if u.path in ("/", "/index.html"):
            if not os.path.isfile(HTML_PATH):
                return self._send(500, "text/plain", "voice_studio.html missing")
            return self._send(200, "text/html; charset=utf-8",
                              open(HTML_PATH, encoding="utf-8").read())
        if u.path == "/api/state":
            q = parse_qs(u.query)
            files = ([f.strip() for f in q["files"][0].split(",") if f.strip()]
                     if q.get("files") else self.files)
            return self._json(200, build_state(files, self.cfg))
        if u.path == "/api/clip":
            h = parse_qs(u.query).get("hash", [""])[0]
            path = os.path.join(gv.VOICE_DIR, h + ".mp3")
            if h and os.path.isfile(path):
                return self._send(200, "audio/mpeg", open(path, "rb").read())
            return self._send(404, "text/plain", "no clip")
        return self._send(404, "text/plain", "not found")

    def do_POST(self):
        u = urlparse(self.path)
        try:
            body = self._body()
        except Exception as e:
            return self._json(400, {"error": f"bad json: {e}"})
        try:
            if u.path == "/api/preview":
                audio = preview_clip(self.cfg, body)
                return self._send(200, "audio/mpeg", audio)
            if u.path == "/api/pick":
                with _write_lock:
                    data = load_overrides()
                    h = body["hash"]
                    if body.get("clear"):
                        data.pop(h, None)
                    else:
                        data[h] = {
                            "speaker": body["speaker"],
                            "text": body["text"],
                            "voice_id": body["voice_id"],
                            "voice_settings": body.get("voice_settings") or {},
                            "picked_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
                        }
                    save_overrides(data)
                    n = sum(1 for k in data if k != "_comment")
                return self._json(200, {"ok": True, "picks": n})
            if u.path == "/api/generate":
                results = generate_clips(self.cfg, body.get("items", []))
                return self._json(200, {"results": results})
        except RuntimeError as e:
            return self._json(400, {"error": str(e)})
        except Exception as e:  # noqa: BLE001 - surface any server error to the UI
            return self._json(500, {"error": f"{type(e).__name__}: {e}"})
        return self._send(404, "text/plain", "not found")

    def log_message(self, *a):
        pass


def main():
    ap = argparse.ArgumentParser(description="Iron Wake voice casting studio.")
    ap.add_argument("--all", action="store_true", help="every scripts/*.gd file")
    ap.add_argument("--files", nargs="+", help="specific .gd files (repo-relative)")
    ap.add_argument("--port", type=int, default=PORT)
    args = ap.parse_args()

    cfg = gv.load_config()
    if args.files:
        files = args.files
    elif args.all:
        files = sorted(os.path.join("scripts", f)
                       for f in os.listdir(gv.SCRIPTS_DIR) if f.endswith(".gd"))
    else:
        files = gv.DEFAULT_FILES  # beach room prototype

    Handler.cfg = cfg
    Handler.files = files
    state = build_state(files, cfg)
    n_lines = len(state["lines"])

    srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"Voice Casting Studio: http://127.0.0.1:{args.port}/")
    print(f"Scope: {', '.join(files)}  ({n_lines} lines, {state['picks']} already picked)")
    if not state["have_key"]:
        print("  ! no ELEVENLABS_API_KEY in tools/.env — preview/generate disabled")
    print("Pick a voice + delivery per line, Preview, Save. Ctrl-C to stop.")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")


if __name__ == "__main__":
    main()
