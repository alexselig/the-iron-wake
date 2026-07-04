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


def _sample_lines(lines, n):
    """Pick up to n lines, round-robining across speakers so a small preview
    still covers everyone (falls back to first-n for a single speaker)."""
    by_spk = {}
    for spk, text in lines:
        by_spk.setdefault(spk, []).append((spk, text))
    picked = []
    i = 0
    while len(picked) < n and any(i < len(v) for v in by_spk.values()):
        for spk in by_spk:
            if i < len(by_spk[spk]) and len(picked) < n:
                picked.append(by_spk[spk][i])
        i += 1
    return picked


def extract_ordered(rel_files, include_responses):
    """Return the full, source-ordered list of (speaker, text) pairs (with
    duplicates). Source order matters for request stitching — a line's spoken
    neighbours condition its prosody."""
    seq = []

    def add(speaker, raw_body):
        text = normalize(_unescape(raw_body))
        if text:
            seq.append((speaker, text))

    for rel in rel_files:
        path = os.path.join(ROOT, rel)
        if not os.path.isfile(path):
            print(f"  ! skip missing file: {rel}", file=sys.stderr)
            continue
        src = open(path, encoding="utf-8").read()
        # Merge _say (Rowan) and _say_as (named) matches by source position so the
        # sequence reflects true script order, not "all _say then all _say_as".
        matches = [(m.start(), "ROWAN", m.group(2)) for m in _RE_SAY.finditer(src)]
        matches += [
            (m.start(), m.group(2), m.group(4)) for m in _RE_SAY_AS.finditer(src)
        ]
        matches.sort(key=lambda x: x[0])
        for _, spk, body in matches:
            add(spk, body)

    if include_responses:
        for rel in RESPONSE_FILES:
            path = os.path.join(ROOT, rel)
            if not os.path.isfile(path):
                continue
            src = open(path, encoding="utf-8").read()
            for block in _RE_RESPONSE_BLOCK.finditer(src):
                for sm in _RE_STRING.finditer(block.group(1)):
                    add("ROWAN", sm.group(2))
    return seq


def dedup_ordered(seq):
    """Unique (speaker, text) pairs, first-occurrence order — the work queue."""
    seen = set()
    out = []
    for spk, text in seq:
        key = (spk, text)
        if key in seen:
            continue
        seen.add(key)
        out.append((spk, text))
    return out


def build_context(seq):
    """Map (speaker, text) -> (previous_text, next_text) for request stitching.

    Context is the immediately adjacent line ONLY when it is the SAME speaker (a
    contiguous run of that character's speech). Different-speaker neighbours are
    left blank — feeding another voice's line as previous_text confuses prosody.
    A line reused in several places takes the context of its FIRST occurrence
    (clips are keyed by hash(speaker|text), so one line = one clip)."""
    ctx = {}
    for i, (spk, text) in enumerate(seq):
        key = (spk, text)
        if key in ctx:
            continue
        prev = seq[i - 1][1] if i > 0 and seq[i - 1][0] == spk else ""
        nxt = seq[i + 1][1] if i + 1 < len(seq) and seq[i + 1][0] == spk else ""
        ctx[key] = (prev, nxt)
    return ctx


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
    cfg.setdefault("speaker_settings", {})
    cfg.setdefault("speakers", {})
    return cfg


def settings_for(cfg, speaker, cli_overrides):
    """Effective voice_settings for a speaker: base <- per-speaker <- CLI.
    CLI overrides win (they exist for A/B testing across all speakers)."""
    merged = dict(cfg["voice_settings"])
    merged.update(cfg["speaker_settings"].get(speaker, {}))
    merged.update(cli_overrides)
    return merged


# ---- synthesis ---------------------------------------------------------------

def synth(api_key, voice_id, text, cfg, voice_settings, previous_text="", next_text=""):
    url = f"{API_BASE}/{voice_id}?output_format={cfg['output_format']}"
    payload = {
        "text": text,
        "model_id": cfg["model_id"],
        "voice_settings": voice_settings,
    }
    # Request stitching: give the model the surrounding same-speaker lines so a
    # clip doesn't sound like it's read cold. Only sent when present.
    if previous_text:
        payload["previous_text"] = previous_text
    if next_text:
        payload["next_text"] = next_text
    body = json.dumps(payload).encode("utf-8")
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
    # ---- preview / A-B flags (non-breaking; defaults = current behavior) --------
    ap.add_argument(
        "--out-dir",
        help="write clips + a local manifest here instead of assets/voice "
        "(use for A/B previews so shipping clips are never touched)",
    )
    ap.add_argument(
        "--speakers",
        help="comma-separated speaker filter, e.g. ROWAN,PINDLE,TIBBIT",
    )
    ap.add_argument(
        "--sample",
        type=int,
        help="cap to N lines; round-robins across the filtered speakers so a small "
        "preview still covers everyone",
    )
    ap.add_argument("--stability", type=float, help="override voice_settings.stability")
    ap.add_argument("--style", type=float, help="override voice_settings.style")
    ap.add_argument(
        "--no-stitch",
        action="store_true",
        help="disable previous_text/next_text request stitching (for A/B testing)",
    )
    args = ap.parse_args()

    cfg = load_config()

    # CLI overrides for A/B (win over base + per-speaker settings).
    cli_overrides = {}
    if args.stability is not None:
        cli_overrides["stability"] = args.stability
    if args.style is not None:
        cli_overrides["style"] = args.style

    out_dir = os.path.abspath(args.out_dir) if args.out_dir else VOICE_DIR
    manifest_path = os.path.join(out_dir, "manifest.json")

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

    seq = extract_ordered(files, include_responses=True)
    lines = dedup_ordered(seq)
    context = {} if args.no_stitch else build_context(seq)

    if args.speakers:
        wanted = {s.strip().upper() for s in args.speakers.split(",") if s.strip()}
        lines = [(s, t) for (s, t) in lines if s in wanted]
    if args.sample is not None and args.sample > 0:
        lines = _sample_lines(lines, args.sample)
    total_chars = sum(len(t) for _, t in lines)
    by_speaker = {}
    for spk, t in lines:
        by_speaker.setdefault(spk, [0, 0])
        by_speaker[spk][0] += 1
        by_speaker[spk][1] += len(t)

    stitch = "off" if args.no_stitch else f"{sum(1 for v in context.values() if v[0] or v[1])} ctx"
    print(f"Scope: {', '.join(files)} (+ shared verb responses)")
    print(f"Lines: {len(lines)}  |  Characters: {total_chars}  |  stitch: {stitch}")
    print(f"Model: {cfg['model_id']}")
    if out_dir != VOICE_DIR:
        print(f"Out dir: {out_dir}  (preview — shipping clips untouched)")
    for spk in sorted(by_speaker, key=lambda s: -by_speaker[s][1]):
        n, c = by_speaker[spk]
        vid = cfg["speakers"].get(spk, cfg["default_voice"])
        sv = settings_for(cfg, spk, cli_overrides)
        print(
            f"  {spk:<10} {n:>4} lines  {c:>6} chars  "
            f"stab={sv.get('stability')} style={sv.get('style')}  -> {vid}"
        )

    if args.dry_run:
        print("\n(dry run — no audio generated)")
        return

    os.makedirs(out_dir, exist_ok=True)
    api_key = load_env()
    manifest = {}
    if os.path.isfile(manifest_path):
        try:
            manifest = json.load(open(manifest_path, encoding="utf-8"))
        except Exception:
            manifest = {}

    generated = skipped = failed = 0
    print()
    for spk, text in lines:
        h = line_hash(spk, text)
        out_path = os.path.join(out_dir, h + ".mp3")
        voice_id = cfg["speakers"].get(spk, cfg["default_voice"])
        entry = {
            "speaker": spk,
            "voice_id": voice_id,
            "chars": len(text),
            "text": text,
            "file": f"{os.path.basename(out_dir)}/{h}.mp3",
        }
        if os.path.isfile(out_path) and not args.force:
            manifest[h] = entry
            skipped += 1
            continue
        preview = text if len(text) <= 48 else text[:45] + "..."
        prev_text, next_text = context.get((spk, text), ("", ""))
        vsettings = settings_for(cfg, spk, cli_overrides)
        try:
            audio = synth(api_key, voice_id, text, cfg, vsettings, prev_text, next_text)
            with open(out_path, "wb") as f:
                f.write(audio)
            manifest[h] = entry
            generated += 1
            print(f"  [{spk}] {preview}  ({len(audio)} bytes)")
            time.sleep(0.25)  # be gentle on rate limits
        except RuntimeError as e:
            failed += 1
            print(f"  ! FAILED [{spk}] {preview}\n      {e}", file=sys.stderr)

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(
        f"\nDone. generated={generated} skipped={skipped} failed={failed} "
        f"total_clips={len(manifest)}"
    )
    print(f"Manifest: {manifest_path}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
