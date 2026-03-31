#!/usr/bin/env python3
"""Generate simple sound effects for The Iron Wake."""

import os
import struct
import math
import wave

SFX_DIR = os.path.expanduser("~/SteampunkBeachDemo/assets/sfx")
SAMPLE_RATE = 22050


def write_wav(filepath, samples, sample_rate=SAMPLE_RATE):
    """Write samples (list of floats -1..1) to a WAV file."""
    with wave.open(filepath, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        for s in samples:
            s = max(-1.0, min(1.0, s))
            f.writeframes(struct.pack("<h", int(s * 32767)))


def generate_pickup():
    """Bright ascending chime — item pickup."""
    samples = []
    duration = 0.25
    n = int(SAMPLE_RATE * duration)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Ascending frequency sweep (440 -> 880 Hz)
        freq = 440 + (880 - 440) * (t / duration)
        env = max(0, 1.0 - t / duration) ** 0.5  # Quick decay
        s = math.sin(2 * math.pi * freq * t) * env * 0.6
        # Add harmonic shimmer
        s += math.sin(2 * math.pi * freq * 2.0 * t) * env * 0.2
        samples.append(s)
    return samples


def generate_door():
    """Heavy wooden door creak + thud."""
    samples = []
    duration = 0.4
    n = int(SAMPLE_RATE * duration)
    import random
    random.seed(42)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Low thud
        thud_env = max(0, 1.0 - t / 0.15) ** 2 if t < 0.15 else 0
        thud = math.sin(2 * math.pi * 80 * t) * thud_env * 0.7
        # Creak noise (filtered noise with resonance)
        creak_env = max(0, 1.0 - t / duration)
        noise = (random.random() * 2 - 1)
        creak = noise * math.sin(2 * math.pi * 200 * t) * creak_env * 0.15
        samples.append(thud + creak)
    return samples


def generate_blip():
    """Short dialogue blip — typewriter-like tick."""
    samples = []
    duration = 0.04
    n = int(SAMPLE_RATE * duration)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1.0 - t / duration) ** 3
        # Quick square-ish wave
        freq = 600
        s = (1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0) * env * 0.3
        samples.append(s)
    return samples


if __name__ == "__main__":
    os.makedirs(SFX_DIR, exist_ok=True)

    effects = {
        "pickup.wav": generate_pickup,
        "door.wav": generate_door,
        "dialogue_blip.wav": generate_blip,
    }

    for name, gen_func in effects.items():
        path = os.path.join(SFX_DIR, name)
        if os.path.exists(path):
            print(f"  [SKIP] {name}")
            continue
        samples = gen_func()
        write_wav(path, samples)
        print(f"  [OK] {name} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

    print("\nDone! SFX files written to assets/sfx/")
