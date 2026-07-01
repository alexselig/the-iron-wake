# Voiceover (ElevenLabs)

Dialogue in The Iron Wake can be voiced with ElevenLabs text-to-speech. Audio is
**pre-generated at build time** — the API key is only used by the generator here
and never ships inside the game. The game loads plain `.mp3` files by content hash.

## How it works

- `tools/generate_voiceover.py` extracts every dialogue line from the room
  scripts, calls ElevenLabs with a per-character voice, and writes one clip to
  `assets/voice/<sha1(speaker|text)>.mp3` plus `assets/voice/manifest.json`.
- At runtime the `VoiceOver` autoload (`scripts/voice_over.gd`) recomputes the
  same `sha1(speaker|text)` hash when a line appears and plays the matching clip.
  If a clip is missing, the line is silent (text-only) — nothing breaks.
- Voice casting lives in `tools/voice_config.json` (safe to commit, no secrets).

## Setup

```bash
cp tools/.env.example tools/.env
# edit tools/.env and set ELEVENLABS_API_KEY=sk_...   (tools/.env is gitignored)
```

The provided key is TTS-only (no `voices_read`/`user_read`). That's fine — the
casting uses ElevenLabs **premade** voices, which don't require those permissions.

## Generate

```bash
python3 tools/generate_voiceover.py --dry-run   # preview lines + character count
python3 tools/generate_voiceover.py             # opening cutscene + beach room (default)
python3 tools/generate_voiceover.py --all       # every room (large API spend)
python3 tools/generate_voiceover.py --files scripts/customs_shack_room.gd
python3 tools/generate_voiceover.py --force     # re-render existing clips
```

Generation is **idempotent**: existing clips are skipped, so re-runs only
synthesize new/changed lines.

## In-game

- Press **V** to toggle voiceover on/off (persisted to `user://voice_settings.cfg`).
- `VoiceOver.set_enabled(bool)` / `VoiceOver.set_volume_db(float)` from code.

## Recasting a character

Edit the `speakers` map in `tools/voice_config.json` (premade ElevenLabs voice
IDs), then re-run with `--force` for the affected scope. No Godot changes needed.
