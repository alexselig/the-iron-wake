#!/usr/bin/env python3
"""Generate ElevenLabs voiceover clips for The Iron Wake.

The API key is read from tools/.env (ELEVENLABS_API_KEY=...) or the environment.
NEVER commit the key. tools/.env is gitignored.

Each dialogue line becomes one clip at:
    assets/voice/<sha1(speaker|normalized_text)>.mp3
The Godot runtime (scripts/voice_over.gd) recomputes the same hash to find the
clip, so the key is only ever used here at build time and never ships in the game.

The hash MUST stay in sync with VoiceOver.line_hash() in scripts/voice_over.gd:
    normalize(s) = collapse runs of whitespace to one space, then strip ends
    hash         = sha1(speaker + "|" + normalize(text))  (lowercase hex)

Usage:
    python3 tools/generate_voiceover.py                # opening + beach room (default)
    python3 tools/generate_voiceover.py --dry-run      # list lines + char count, no API calls
    python3 tools/generate_voiceover.py --all          # every scripts/*.gd file
    python3 tools/generate_voiceover.py --files a.gd b.gd
    python3 tools/generate_voiceover.py --force        # regenerate existing clips
"""
import argparse
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS_DIR = os.path.join(ROOT, "scripts")
VOICE_DIR = os.path.join(ROOT, "assets", "voice")
CONFIG_PATH = os.path.join(ROOT, "tools", "voice_config.json")
ENV_PATH = os.path.join(ROOT, "tools", ".env")
MANIFEST_PATH = os.path.join(VOICE_DIR, "manifest.json")

API_BASE = "https://api.elevenlabs.io/v1/text-to-speech"

# Default scope: the opening cutscene + first room live in beach_room.gd; the
# shared verb-response lines (Rowan) live in adventure_room.gd.
DEFAULT_FILES = ["scripts/beach_room.gd"]
RESPONSE_FILES = ["scripts/adventure_room.gd"]

# ---- extraction --------------------------------------------------------------

_RE_SAY = re.compile(r"""_say\(\s*(["'])((?:\\.|(?!\1).)*)\1\s*\)""")
_RE_SAY_AS = re.compile(
    r"""_say_as\(\s*(["'])([A-Z_]+)\1\s*,\s*(["'])((?:\\.|(?!\3).)*)\3\s*\)"""
)
_RE_RESPONSE_BLOCK = re.compile(
    r"""const\s+_[A-Z_]*RESPONSES\s*:=\s*\[(.*?)\]""", re.DOTALL
)
_RE_STRING = re.compile(r"""(["'])((?:\\.|(?!\1).)*)\1""")


def _unescape(raw: str) -> str:
    """Turn a GDScript string literal body into its runtime value."""
    out = []
    i = 0
    while i < len(raw):
        c = raw[i]
        if c == "\\" and i + 1 < len(raw):
            nxt = raw[i + 1]
            out.append(
                {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\"}.get(
                    nxt, nxt
                )
            )
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def normalize(text: str) -> str:
    """Collapse ASCII whitespace runs, trim ends.

    MUST stay byte-identical to VoiceOver._normalize() in
    scripts/voice_over.gd. Uses an explicit ASCII class (not \\s) so Python and
    Godot's PCRE2 agree exactly.
    """
    return re.sub(r"[ \t\r\n]+", " ", text).strip()


def line_hash(speaker: str, text: str) -> str:
    return hashlib.sha1(
        (speaker + "|" + normalize(text)).encode("utf-8")
    ).hexdigest()


def extract_lines(rel_files, include_responses):
    """Return ordered, de-duplicated list of (speaker, text) pairs."""
    seen = set()
    lines = []

    def add(speaker, raw_body):
        text = normalize(_unescape(raw_body))
        if not text:
            return
        key = (speaker, text)
        if key in seen:
            return
        seen.add(key)
        lines.append((speaker, text))

    for rel in rel_files:
        path = os.path.join(ROOT, rel)
        if not os.path.isfile(path):
            print(f"  ! skip missing file: {rel}", file=sys.stderr)
            continue
        src = open(path, encoding="utf-8").read()
        for m in _RE_SAY.finditer(src):
            add("ROWAN", m.group(2))
        for m in _RE_SAY_AS.finditer(src):
            add(m.group(2), m.group(4))

    if include_responses:
        for rel in RESPONSE_FILES:
            path = os.path.join(ROOT, rel)
            if not os.path.isfile(path):
                continue
            src = open(path, encoding="utf-8").read()
            for block in _RE_RESPONSE_BLOCK.finditer(src):
                for sm in _RE_STRING.finditer(block.group(1)):
                    add("ROWAN", sm.group(2))
    return lines


# ---- config / key ------------------------------------------------------------

def load_env():
    if os.path.isfile(ENV_PATH):
        for raw in open(ENV_PATH, encoding="utf-8"):
            raw = raw.strip()
            if not raw or raw.startswith("#") or "=" not in raw:
                continue
            k, v = raw.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        sys.exit(
            "ERROR: no ELEVENLABS_API_KEY found.\n"
            "  Put it in tools/.env (gitignored):  ELEVENLABS_API_KEY=sk_...\n"
            "  or export it:  export ELEVENLABS_API_KEY=sk_..."
        )
    return key


def load_config():
    cfg = json.load(open(CONFIG_PATH, encoding="utf-8"))
    cfg.setdefault("model_id", "eleven_multilingual_v2")
    cfg.setdefault("output_format", "mp3_44100_128")
    cfg.setdefault("voice_settings", {})
    cfg.setdefault("speakers", {})
    return cfg


# ---- synthesis ---------------------------------------------------------------

def synth(api_key, voice_id, text, cfg):
    url = f"{API_BASE}/{voice_id}?output_format={cfg['output_format']}"
    body = json.dumps(
        {
            "text": text,
            "model_id": cfg["model_id"],
            "voice_settings": cfg["voice_settings"],
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
        method="POST",
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:200]
            if e.code == 429 and attempt < 3:  # rate limited -> back off
                wait = 2 ** attempt
                print(f"    429 rate limited, retrying in {wait}s...")
                time.sleep(wait)
                continue
            raise RuntimeError(f"HTTP {e.code}: {detail}")
        except urllib.error.URLError as e:
            if attempt < 3:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"network error: {e}")
    raise RuntimeError("exhausted retries")


def main():
    ap = argparse.ArgumentParser(description="Generate Iron Wake voiceover clips.")
    ap.add_argument("--all", action="store_true", help="every scripts/*.gd file")
    ap.add_argument("--files", nargs="+", help="specific .gd files (relative to repo root)")
    ap.add_argument("--dry-run", action="store_true", help="list lines, no API calls")
    ap.add_argument("--force", action="store_true", help="regenerate existing clips")
    args = ap.parse_args()

    cfg = load_config()

    if args.files:
        files = args.files
    elif args.all:
        files = sorted(
            os.path.join("scripts", f)
            for f in os.listdir(SCRIPTS_DIR)
            if f.endswith(".gd")
        )
    else:
        files = DEFAULT_FILES

    lines = extract_lines(files, include_responses=True)
    total_chars = sum(len(t) for _, t in lines)
    by_speaker = {}
    for spk, t in lines:
        by_speaker.setdefault(spk, [0, 0])
        by_speaker[spk][0] += 1
        by_speaker[spk][1] += len(t)

    print(f"Scope: {', '.join(files)} (+ shared verb responses)")
    print(f"Lines: {len(lines)}  |  Characters: {total_chars}")
    for spk in sorted(by_speaker, key=lambda s: -by_speaker[s][1]):
        n, c = by_speaker[spk]
        vid = cfg["speakers"].get(spk, cfg["default_voice"])
        print(f"  {spk:<10} {n:>4} lines  {c:>6} chars  -> {vid}")

    if args.dry_run:
        print("\n(dry run — no audio generated)")
        return

    os.makedirs(VOICE_DIR, exist_ok=True)
    api_key = load_env()
    manifest = {}
    if os.path.isfile(MANIFEST_PATH):
        try:
            manifest = json.load(open(MANIFEST_PATH, encoding="utf-8"))
        except Exception:
            manifest = {}

    generated = skipped = failed = 0
    print()
    for spk, text in lines:
        h = line_hash(spk, text)
        out_path = os.path.join(VOICE_DIR, h + ".mp3")
        voice_id = cfg["speakers"].get(spk, cfg["default_voice"])
        entry = {
            "speaker": spk,
            "voice_id": voice_id,
            "chars": len(text),
            "text": text,
            "file": f"assets/voice/{h}.mp3",
        }
        if os.path.isfile(out_path) and not args.force:
            manifest[h] = entry
            skipped += 1
            continue
        preview = text if len(text) <= 48 else text[:45] + "..."
        try:
            audio = synth(api_key, voice_id, text, cfg)
            with open(out_path, "wb") as f:
                f.write(audio)
            manifest[h] = entry
            generated += 1
            print(f"  [{spk}] {preview}  ({len(audio)} bytes)")
            time.sleep(0.25)  # be gentle on rate limits
        except RuntimeError as e:
            failed += 1
            print(f"  ! FAILED [{spk}] {preview}\n      {e}", file=sys.stderr)

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(
        f"\nDone. generated={generated} skipped={skipped} failed={failed} "
        f"total_clips={len(manifest)}"
    )
    print(f"Manifest: {MANIFEST_PATH}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
