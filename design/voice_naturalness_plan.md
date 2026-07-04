# Voice Naturalness Plan — The Iron Wake

Goal: make the ElevenLabs character voices feel natural, not awkward — **without**
regenerating blindly. Chosen scope: **Tiers 1–3**, staying on `eleven_multilingual_v2`
(no v3 API-access risk). Written before any generation.

## Current state (as of this plan)

- Pipeline: `tools/generate_voiceover.py` → `assets/voice/<sha1(speaker|text)>.mp3`;
  runtime `scripts/voice_over.gd` recomputes the same hash. Hash is **text-only**.
- 127 clips voiced: ROWAN 110, TIBBIT 9, PINDLE 8 (opening + beach room + shared
  verb responses). Rest of cast not yet generated.
- Clips are **git-tracked** (128 files) → rollback = `git checkout assets/voice/`.
- Config (`tools/voice_config.json`): model `eleven_multilingual_v2`,
  `stability 0.5`, `similarity_boost 0.75`, `style 0.0`, `use_speaker_boost true`,
  one settings block for all speakers.

## Diagnosis (root causes of "awkward / unnatural", impact order)

1. **No inter-line context.** `synth()` sends each line cold. 127 clips generated in
   isolation → odd intonation at line boundaries. Biggest single cause.
2. **`style: 0.0`** → zero expressiveness; personality-driven cast reads flat.
3. **`stability: 0.5`** → leans monotone; expressive range wants ~0.35–0.45.
4. **Uniform settings for all speakers** → Rowan (dry wit), Pindle (pompous),
   Tibbit (eager) all voiced identically.
5. (Deferred) model `multilingual_v2` and old v1 premade voices — NOT changed in
   this plan; revisit as Tier 4/5 if 1–3 aren't enough.

The dialogue *writing* is good (punctuation + personality present) — not the problem.

## The plan

### Tier 1 — Retune global settings + regenerate
- Edit `tools/voice_config.json` `voice_settings`:
  - `stability` 0.5 → **0.40**
  - `style` 0.0 → **0.45**
  - keep `similarity_boost` 0.75, `use_speaker_boost` true
- Before a full `--force` regen, **A/B a sample** at old vs new settings so we don't
  clobber 127 clips on a guess. The generator has no output-dir override today →
  add a small `--out-dir DIR` (and optional `--sample N`) flag so previews write to a
  scratch folder instead of `assets/voice/`. (Small, additive; default behavior
  unchanged.)
- Pick ~6 representative lines (Rowan sarcasm, Rowan descriptive, Pindle, Tibbit),
  render old vs new into `/tmp/voice_ab/{old,new}`, listen with `afplay`.
- If better: `python3 tools/generate_voiceover.py --force` (default scope = the 127).

### Tier 2 — Request stitching (previous_text / next_text)
- `tools/generate_voiceover.py`:
  - Build the **script-ordered** line list (pre-dedup) so each occurrence knows its
    real neighbors; compute `previous_text` / `next_text` from adjacent lines.
  - For a unique `(speaker, text)` clip (hash key), use the context from its **first
    occurrence** (a reused line shares one clip). Document this tradeoff in code.
  - Add `previous_text` / `next_text` to the `synth()` JSON body.
- Hash stays text-only → **`voice_over.gd` untouched**. Requires `--force` to refresh
  existing clips with context.
- `multilingual_v2` supports stitching, so this is safe on the chosen model.

### Tier 3 — Per-character voice settings
- `tools/voice_config.json`: add optional `speaker_settings` map, e.g.
  `{"ROWAN": {"stability":0.35,"style":0.55}, "PINDLE": {"stability":0.55,"style":0.30},
    "TIBBIT": {"stability":0.35,"style":0.60}}`.
- `generate_voiceover.py`: merge base `voice_settings` + per-speaker override at the
  call site (override wins). No override = base settings.
- Starting values from `_casting_notes`; tune by ear on the A/B samples.

## Verification
- `python3 tools/generate_voiceover.py --dry-run` — confirm extraction unchanged
  (still 127 lines) after code edits.
- A/B listen with `afplay` before any full regen.
- After regen, launch game windowed (detached) and hear lines in context; press **V**
  to toggle.
- Manifest line count must stay 127 (no accidental line loss).

## Rollback
- Any regen is reversible: `git checkout assets/voice/` restores tracked clips +
  manifest. Config/tool edits revert via git.

## Out of scope (this plan)
- `eleven_v3` upgrade + emotional audio tags (Tier 4) — needs API-access check + a
  hash strategy for tags (hash clean text, send tagged).
- Recasting voices (Tier 5).
- Generating the unvoiced rest of the cast (`--all`).

## Task list
1. Add `--out-dir` / `--sample` preview flags to the generator (non-breaking).
2. Tier 1: edit settings; render old-vs-new A/B sample; listen; decide.
3. Tier 2: implement stitching (ordered neighbors, first-occurrence context).
4. Tier 3: per-speaker settings schema + merge.
5. Full `--force` regen of the 127-clip default scope.
6. Verify in-game (windowed) + manifest count; commit or `git checkout` to roll back.
