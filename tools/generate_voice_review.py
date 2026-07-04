#!/usr/bin/env python3
"""Generate a blind A/B voice-review set for The Iron Wake.

Renders a curated subset of dialogue lines under several *settings profiles*, so
you can listen and pick which delivery you prefer per line. Because the shipping
hash is text-only (same line -> same file), profile clips are named
`<profile>__<hash>.mp3` to avoid collisions.

Output (all under /tmp/voice_review/):
    clips/<profile>__<sha1(speaker|text)>.mp3
    review.json   # [{id, speaker, text, options:[{profile, file}]}], options
                  # SHUFFLED per line; the web app hides profile labels.

Then run the review app:  python3 tools/voice_review_server.py
Nothing under assets/voice/ is touched.
"""
import json
import os
import random
import sys

# Reuse the shipping generator's extraction + synth so hashing/normalization
# stay byte-identical.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_voiceover as gv  # noqa: E402

REVIEW_DIR = "/tmp/voice_review"
CLIPS_DIR = os.path.join(REVIEW_DIR, "clips")

# Settings profiles to compare. Each = voice_settings + whether to use request
# stitching + whether to apply the per-speaker override map from voice_config.
PROFILES = {
    "original": {
        "settings": {"stability": 0.5, "similarity_boost": 0.75, "style": 0.0,
                     "use_speaker_boost": True},
        "stitch": False, "per_speaker": False,
    },
    "expressive": {
        "settings": {"stability": 0.4, "similarity_boost": 0.75, "style": 0.45,
                     "use_speaker_boost": True},
        "stitch": True, "per_speaker": False,
    },
    "per_character": {
        # base; per-speaker overrides from voice_config.json are layered on top
        "settings": {"stability": 0.4, "similarity_boost": 0.75, "style": 0.45,
                     "use_speaker_boost": True},
        "stitch": True, "per_speaker": True,
    },
    "max_expressive": {
        "settings": {"stability": 0.3, "similarity_boost": 0.75, "style": 0.65,
                     "use_speaker_boost": True},
        "stitch": True, "per_speaker": False,
    },
}

# How many lines per speaker to include in the review subset.
SUBSET = {"ROWAN": 6, "PINDLE": 3, "TIBBIT": 3}


def pick_subset(lines):
    """Even spread of lines per speaker (variety over first-N)."""
    by_spk = {}
    for s, t in lines:
        by_spk.setdefault(s, []).append((s, t))
    chosen = []
    for spk, want in SUBSET.items():
        pool = by_spk.get(spk, [])
        if not pool:
            continue
        if len(pool) <= want:
            chosen.extend(pool)
        else:
            step = len(pool) / want
            chosen.extend(pool[int(i * step)] for i in range(want))
    return chosen


def main():
    cfg = gv.load_config()
    api_key = gv.load_env()
    os.makedirs(CLIPS_DIR, exist_ok=True)

    seq = gv.extract_ordered(gv.DEFAULT_FILES, include_responses=True)
    context = gv.build_context(seq)
    subset = pick_subset(gv.dedup_ordered(seq))

    print(f"Review subset: {len(subset)} lines x {len(PROFILES)} profiles = "
          f"{len(subset) * len(PROFILES)} clips")

    review = []
    made = failed = 0
    for idx, (spk, text) in enumerate(subset):
        h = gv.line_hash(spk, text)
        voice_id = cfg["speakers"].get(spk, cfg["default_voice"])
        prev_ctx, next_ctx = context.get((spk, text), ("", ""))
        options = []
        for pname, prof in PROFILES.items():
            vs = dict(prof["settings"])
            if prof["per_speaker"]:
                vs.update(cfg.get("speaker_settings", {}).get(spk, {}))
            prev_t = prev_ctx if prof["stitch"] else ""
            next_t = next_ctx if prof["stitch"] else ""
            fname = f"{pname}__{h}.mp3"
            fpath = os.path.join(CLIPS_DIR, fname)
            if not os.path.isfile(fpath):
                try:
                    audio = gv.synth(api_key, voice_id, text, cfg, vs, prev_t, next_t)
                    with open(fpath, "wb") as f:
                        f.write(audio)
                    made += 1
                except RuntimeError as e:
                    failed += 1
                    print(f"  ! FAILED [{pname}] {text[:40]!r}: {e}", file=sys.stderr)
                    continue
            options.append({"profile": pname, "file": f"clips/{fname}"})
        random.shuffle(options)  # blind: web app hides labels + uses this order
        review.append({"id": idx, "speaker": spk, "text": text, "options": options})
        print(f"  [{spk}] {text[:50]!r}  ({len(options)} variants)")

    with open(os.path.join(REVIEW_DIR, "review.json"), "w", encoding="utf-8") as f:
        json.dump({"profiles": list(PROFILES), "items": review}, f, indent=2,
                  ensure_ascii=False)
    print(f"\nDone. generated={made} failed={failed}")
    print(f"Review manifest: {os.path.join(REVIEW_DIR, 'review.json')}")
    print("Next: python3 tools/voice_review_server.py")


if __name__ == "__main__":
    main()
