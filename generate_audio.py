#!/usr/bin/env python3
"""Generate steampunk-themed sound effects and music for The Iron Wake.

Uses numpy for synthesis — no external audio libraries needed.
All output is 44100 Hz, 16-bit WAV.
"""

import os
import struct
import wave
import numpy as np

BASE = os.path.expanduser("~/SteampunkBeachDemo/assets")
SFX_DIR = os.path.join(BASE, "sfx")
MUSIC_DIR = os.path.join(BASE, "music")
SAMPLE_RATE = 44100

os.makedirs(SFX_DIR, exist_ok=True)
os.makedirs(MUSIC_DIR, exist_ok=True)


def save_wav(filename: str, samples: np.ndarray, directory: str = SFX_DIR):
    """Save numpy float array (-1 to 1) as 16-bit WAV."""
    path = os.path.join(directory, filename)
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm.tobytes())
    print(f"  Saved: {path} ({len(samples)/SAMPLE_RATE:.2f}s)")


def sine(freq: float, duration: float, phase: float = 0.0) -> np.ndarray:
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), endpoint=False)
    return np.sin(2 * np.pi * freq * t + phase)


def noise(duration: float) -> np.ndarray:
    return np.random.uniform(-1, 1, int(SAMPLE_RATE * duration))


def envelope(samples: np.ndarray, attack: float = 0.01, decay: float = 0.1,
             sustain: float = 0.7, release: float = 0.1) -> np.ndarray:
    """ADSR envelope."""
    n = len(samples)
    env = np.ones(n)
    a = int(attack * SAMPLE_RATE)
    d = int(decay * SAMPLE_RATE)
    r = int(release * SAMPLE_RATE)

    # Attack
    if a > 0:
        env[:a] = np.linspace(0, 1, a)
    # Decay
    if d > 0 and a + d < n:
        env[a:a+d] = np.linspace(1, sustain, d)
    # Sustain
    if a + d < n - r:
        env[a+d:n-r] = sustain
    # Release
    if r > 0:
        env[-r:] = np.linspace(sustain, 0, r)
    return samples * env


def fade_out(samples: np.ndarray, duration: float = 0.05) -> np.ndarray:
    n = int(duration * SAMPLE_RATE)
    if n > len(samples):
        n = len(samples)
    samples[-n:] *= np.linspace(1, 0, n)
    return samples


def fade_in(samples: np.ndarray, duration: float = 0.01) -> np.ndarray:
    n = int(duration * SAMPLE_RATE)
    if n > len(samples):
        n = len(samples)
    samples[:n] *= np.linspace(0, 1, n)
    return samples


# ============================================================
# SOUND EFFECTS
# ============================================================

def generate_pickup():
    """Brass chime — picking up an item. Bright metallic ascending notes."""
    dur = 0.4
    # Two ascending brass tones with harmonics
    t1 = sine(880, dur) * 0.4 + sine(1760, dur) * 0.15 + sine(2640, dur) * 0.05
    t2 = sine(1100, dur) * 0.35 + sine(2200, dur) * 0.12
    # Stagger the second tone
    delay = int(0.08 * SAMPLE_RATE)
    padded = np.zeros(len(t1) + delay)
    padded[:len(t1)] += t1
    padded[delay:delay+len(t2)] += t2
    # Metallic shimmer
    shimmer = sine(4400, len(padded)/SAMPLE_RATE) * 0.03
    padded[:len(shimmer)] += shimmer
    result = envelope(padded, attack=0.005, decay=0.08, sustain=0.3, release=0.2)
    save_wav("pickup.wav", result * 0.7)


def generate_door():
    """Heavy brass door — mechanical clunk with steam hiss."""
    dur = 0.8
    # Low metallic thud
    thud = sine(120, 0.15) * 0.8 + sine(80, 0.15) * 0.5
    thud = envelope(thud, attack=0.002, decay=0.05, sustain=0.2, release=0.08)
    # Mechanical click/latch
    click = noise(0.03) * 0.6
    click = fade_out(click, 0.02)
    # Steam hiss (filtered noise)
    hiss_raw = noise(0.5)
    # Bandpass via simple mixing of filtered components
    t_hiss = np.linspace(0, 0.5, int(SAMPLE_RATE * 0.5), endpoint=False)
    hiss = hiss_raw * np.sin(2 * np.pi * 3000 * t_hiss) * 0.15
    hiss = envelope(hiss, attack=0.05, decay=0.1, sustain=0.4, release=0.25)
    # Combine
    total = np.zeros(int(SAMPLE_RATE * dur))
    total[:len(thud)] += thud
    total[int(0.05*SAMPLE_RATE):int(0.05*SAMPLE_RATE)+len(click)] += click
    total[int(0.12*SAMPLE_RATE):int(0.12*SAMPLE_RATE)+len(hiss)] += hiss
    # Creak
    creak_t = np.linspace(0, 0.3, int(SAMPLE_RATE * 0.3), endpoint=False)
    creak = np.sin(2 * np.pi * (200 + 100 * creak_t) * creak_t) * 0.15
    creak = envelope(creak, attack=0.02, decay=0.1, sustain=0.3, release=0.1)
    total[int(0.08*SAMPLE_RATE):int(0.08*SAMPLE_RATE)+len(creak)] += creak
    save_wav("door.wav", total * 0.8)


def generate_dialogue_blip():
    """Short brass 'pip' for dialogue text reveal — warm and subtle."""
    dur = 0.045
    # Warm brass tone
    blip = sine(520, dur) * 0.5 + sine(1040, dur) * 0.2 + sine(260, dur) * 0.15
    blip = envelope(blip, attack=0.003, decay=0.015, sustain=0.3, release=0.015)
    save_wav("dialogue_blip.wav", blip * 0.5)


def generate_puzzle_solve():
    """Triumphant brass fanfare — puzzle completed."""
    dur = 1.2
    total = np.zeros(int(SAMPLE_RATE * dur))
    # Ascending major chord: C5 E5 G5 C6
    notes = [(523, 0.0), (659, 0.15), (784, 0.3), (1047, 0.45)]
    for freq, offset in notes:
        start = int(offset * SAMPLE_RATE)
        tone_dur = dur - offset
        tone = sine(freq, tone_dur) * 0.3 + sine(freq*2, tone_dur) * 0.1
        tone = envelope(tone, attack=0.01, decay=0.1, sustain=0.5, release=0.3)
        total[start:start+len(tone)] += tone
    # Shimmer on top
    shimmer = sine(2093, 0.4) * 0.05
    shimmer = envelope(shimmer, attack=0.3, decay=0.05, sustain=0.2, release=0.1)
    total[int(0.6*SAMPLE_RATE):int(0.6*SAMPLE_RATE)+len(shimmer)] += shimmer
    save_wav("puzzle_solve.wav", total * 0.7)


def generate_steam_valve():
    """Steam release — hissing with pressure drop."""
    dur = 0.6
    hiss = noise(dur) * 0.4
    # Frequency sweep to simulate pressure drop
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    sweep = np.sin(2 * np.pi * (4000 - 2000 * t/dur) * t) * 0.1
    combined = hiss + sweep
    combined = envelope(combined, attack=0.01, decay=0.05, sustain=0.6, release=0.3)
    save_wav("steam_valve.wav", combined * 0.6)


def generate_item_combine():
    """Mechanical clicking — combining inventory items."""
    dur = 0.35
    total = np.zeros(int(SAMPLE_RATE * dur))
    # Series of metallic clicks
    for i, offset in enumerate([0.0, 0.07, 0.12, 0.18]):
        start = int(offset * SAMPLE_RATE)
        click = noise(0.025) * 0.3 + sine(800 + i*200, 0.025) * 0.4
        click = fade_out(click, 0.015)
        end = min(start + len(click), len(total))
        total[start:end] += click[:end-start]
    # Final satisfying lock
    lock = sine(600, 0.08) * 0.5 + sine(1200, 0.08) * 0.2
    lock = envelope(lock, attack=0.002, decay=0.03, sustain=0.3, release=0.04)
    start = int(0.22 * SAMPLE_RATE)
    total[start:start+len(lock)] += lock
    save_wav("item_combine.wav", total * 0.7)


def generate_memory_vision():
    """Ethereal shimmer — memory vision transition. Dreamy, reverberant."""
    dur = 2.5
    total = np.zeros(int(SAMPLE_RATE * dur))
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Shimmering high tones with slow beating
    shimmer1 = np.sin(2 * np.pi * 1200 * t) * 0.15 * np.sin(2 * np.pi * 0.5 * t)
    shimmer2 = np.sin(2 * np.pi * 1207 * t) * 0.15 * np.sin(2 * np.pi * 0.4 * t)
    # Low drone
    drone = np.sin(2 * np.pi * 150 * t) * 0.12 + np.sin(2 * np.pi * 225 * t) * 0.08
    # Wind-like pad
    wind = noise(dur) * 0.04
    # Gentle bell
    bell = np.sin(2 * np.pi * 800 * t) * np.exp(-t * 1.5) * 0.2
    total = shimmer1 + shimmer2 + drone + wind + bell
    total = envelope(total, attack=0.5, decay=0.3, sustain=0.6, release=0.8)
    save_wav("memory_vision.wav", total * 0.6)


def generate_footstep():
    """Soft footstep on stone/wood."""
    dur = 0.12
    # Thump
    thump = sine(100, dur) * 0.4
    thump = envelope(thump, attack=0.002, decay=0.03, sustain=0.1, release=0.06)
    # Scrape
    scrape = noise(0.06) * 0.15
    scrape = fade_out(scrape, 0.04)
    total = np.zeros(int(SAMPLE_RATE * dur))
    total[:len(thump)] += thump
    total[:len(scrape)] += scrape
    save_wav("footstep.wav", total * 0.7)


def generate_ui_click():
    """Clean UI click for verb panel selection."""
    dur = 0.06
    click = sine(1000, dur) * 0.3 + sine(2000, dur) * 0.1
    click = envelope(click, attack=0.002, decay=0.02, sustain=0.1, release=0.03)
    save_wav("ui_click.wav", click * 0.5)


def generate_error_buzz():
    """Wrong action / can't do that — brief low buzz."""
    dur = 0.2
    buzz = sine(180, dur) * 0.3 + sine(190, dur) * 0.3  # Beating
    buzz += sine(360, dur) * 0.1
    buzz = envelope(buzz, attack=0.005, decay=0.05, sustain=0.4, release=0.08)
    save_wav("error_buzz.wav", buzz * 0.5)


# ============================================================
# MUSIC — Ambient steampunk loops
# ============================================================

def generate_harbor_ambient():
    """Harbor ambient — gentle waves, distant machinery, seagull hints.
    60-second seamless loop."""
    dur = 60.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    total = np.zeros(n)

    # Ocean waves — slow modulated noise
    wave_noise = noise(dur) * 0.06
    wave_mod = (np.sin(2 * np.pi * 0.08 * t) * 0.5 + 0.5)  # ~12s cycle
    wave_mod2 = (np.sin(2 * np.pi * 0.05 * t) * 0.3 + 0.7)
    total += wave_noise * wave_mod * wave_mod2

    # Distant steam machinery — low rumble with rhythmic pulsing
    machine = np.sin(2 * np.pi * 55 * t) * 0.04
    machine += np.sin(2 * np.pi * 82 * t) * 0.02
    machine_pulse = (np.sin(2 * np.pi * 0.7 * t) * 0.5 + 0.5)  # Rhythmic
    total += machine * machine_pulse

    # Wind
    wind = noise(dur) * 0.03
    wind_mod = (np.sin(2 * np.pi * 0.03 * t) * 0.5 + 0.5)
    total += wind * wind_mod

    # Occasional distant bell (every ~20s)
    for bell_time in [18.0, 35.0, 52.0]:
        start = int(bell_time * SAMPLE_RATE)
        bell_dur = 3.0
        bell_n = int(bell_dur * SAMPLE_RATE)
        bell_t = np.linspace(0, bell_dur, bell_n, endpoint=False)
        bell = np.sin(2 * np.pi * 440 * bell_t) * np.exp(-bell_t * 1.2) * 0.06
        bell += np.sin(2 * np.pi * 880 * bell_t) * np.exp(-bell_t * 1.8) * 0.02
        end = min(start + bell_n, n)
        total[start:end] += bell[:end-start]

    # Gentle pad for warmth — fifths
    pad = np.sin(2 * np.pi * 110 * t) * 0.03
    pad += np.sin(2 * np.pi * 165 * t) * 0.02
    pad_mod = (np.sin(2 * np.pi * 0.02 * t) * 0.3 + 0.7)
    total += pad * pad_mod

    # Crossfade for seamless loop (2 seconds)
    xfade = int(2.0 * SAMPLE_RATE)
    total[-xfade:] *= np.linspace(1, 0, xfade)
    total[:xfade] *= np.linspace(0, 1, xfade)

    save_wav("harbor_ambient.wav", total * 0.8, MUSIC_DIR)


def generate_lighthouse_ambient():
    """Lighthouse interior — eerie, ancient, resonant. 60-second loop."""
    dur = 60.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    total = np.zeros(n)

    # Deep resonant drone — the lighthouse hums
    drone = np.sin(2 * np.pi * 82 * t) * 0.06
    drone += np.sin(2 * np.pi * 123 * t) * 0.04  # Fifth above
    drone += np.sin(2 * np.pi * 164 * t) * 0.02
    drone_mod = (np.sin(2 * np.pi * 0.015 * t) * 0.3 + 0.7)
    total += drone * drone_mod

    # Wind through cracks — filtered noise, slow swell
    wind = noise(dur) * 0.04
    wind_mod = np.abs(np.sin(2 * np.pi * 0.04 * t))
    total += wind * wind_mod

    # Mysterious high tones — like the lens mechanism
    for tone_time in [8, 22, 38, 52]:
        start = int(tone_time * SAMPLE_RATE)
        tone_dur = 4.0
        tone_n = int(tone_dur * SAMPLE_RATE)
        tone_t = np.linspace(0, tone_dur, tone_n, endpoint=False)
        freq = np.random.choice([660, 784, 880, 990])
        tone = np.sin(2 * np.pi * freq * tone_t) * 0.04
        tone *= np.sin(np.pi * tone_t / tone_dur)  # Smooth in/out
        end = min(start + tone_n, n)
        total[start:end] += tone[:end-start]

    # Creaking brass — occasional
    for creak_time in [12, 30, 48]:
        start = int(creak_time * SAMPLE_RATE)
        creak_dur = 0.8
        creak_n = int(creak_dur * SAMPLE_RATE)
        creak_t = np.linspace(0, creak_dur, creak_n, endpoint=False)
        creak = np.sin(2 * np.pi * (300 + 200 * np.sin(2*np.pi*3*creak_t)) * creak_t) * 0.03
        creak *= np.sin(np.pi * creak_t / creak_dur)
        end = min(start + creak_n, n)
        total[start:end] += creak[:end-start]

    # Heartbeat-like sub pulse
    for beat_time in np.arange(0, dur, 3.5):
        start = int(beat_time * SAMPLE_RATE)
        beat_dur = 0.4
        beat_n = int(beat_dur * SAMPLE_RATE)
        beat_t = np.linspace(0, beat_dur, beat_n, endpoint=False)
        beat = np.sin(2 * np.pi * 40 * beat_t) * np.exp(-beat_t * 6) * 0.06
        end = min(start + beat_n, n)
        total[start:end] += beat[:end-start]

    # Crossfade for loop
    xfade = int(2.0 * SAMPLE_RATE)
    total[-xfade:] *= np.linspace(1, 0, xfade)
    total[:xfade] *= np.linspace(0, 1, xfade)

    save_wav("lighthouse_ambient.wav", total * 0.8, MUSIC_DIR)


def generate_bazaar_ambient():
    """Bustling bazaar — crowd murmur, clanking, mechanical sounds. 60s loop."""
    dur = 60.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    total = np.zeros(n)

    # Crowd murmur — low filtered noise with variation
    murmur = noise(dur) * 0.05
    murmur_mod = (np.sin(2 * np.pi * 0.1 * t) * 0.3 + 0.7)
    murmur_mod *= (np.sin(2 * np.pi * 0.07 * t) * 0.2 + 0.8)
    total += murmur * murmur_mod

    # Rhythmic hammering/clanking
    for clank_time in np.arange(0, dur, 1.8):
        start = int(clank_time * SAMPLE_RATE)
        clank_dur = 0.08
        clank_n = int(clank_dur * SAMPLE_RATE)
        clank_t = np.linspace(0, clank_dur, clank_n, endpoint=False)
        freq = np.random.choice([800, 1000, 1200, 600])
        clank = (np.sin(2*np.pi*freq*clank_t) * 0.08 + noise(clank_dur)[:clank_n] * 0.04)
        clank *= np.exp(-clank_t * 30)
        end = min(start + clank_n, n)
        total[start:end] += clank[:end-start]

    # Steam puffs
    for puff_time in np.arange(2.5, dur, 4.5):
        start = int(puff_time * SAMPLE_RATE)
        puff_dur = 0.25
        puff_n = int(puff_dur * SAMPLE_RATE)
        puff = noise(puff_dur)[:puff_n] * 0.06
        puff *= np.exp(-np.linspace(0, puff_dur, puff_n) * 8)
        end = min(start + puff_n, n)
        total[start:end] += puff[:end-start]

    # Warm musical pad — major feel
    pad = np.sin(2 * np.pi * 220 * t) * 0.02
    pad += np.sin(2 * np.pi * 277 * t) * 0.015  # Major third
    pad += np.sin(2 * np.pi * 330 * t) * 0.015  # Fifth
    pad_mod = (np.sin(2 * np.pi * 0.025 * t) * 0.3 + 0.7)
    total += pad * pad_mod

    # Crossfade
    xfade = int(2.0 * SAMPLE_RATE)
    total[-xfade:] *= np.linspace(1, 0, xfade)
    total[:xfade] *= np.linspace(0, 1, xfade)

    save_wav("bazaar_ambient.wav", total * 0.7, MUSIC_DIR)


def generate_memory_vision_music():
    """Memory vision music — ethereal, emotional, haunting. 30s."""
    dur = 30.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    total = np.zeros(n)

    # Ethereal pad — minor key, slow evolving
    # Am chord: A3 C4 E4
    total += np.sin(2 * np.pi * 220 * t) * 0.08
    total += np.sin(2 * np.pi * 262 * t) * 0.06
    total += np.sin(2 * np.pi * 330 * t) * 0.06

    # Slow modulation
    total *= (np.sin(2 * np.pi * 0.03 * t) * 0.2 + 0.8)

    # High shimmering — like distant bells
    shimmer = np.sin(2 * np.pi * 880 * t) * 0.03
    shimmer += np.sin(2 * np.pi * 887 * t) * 0.03  # Slow beating
    shimmer_mod = (np.sin(2 * np.pi * 0.08 * t) * 0.5 + 0.5)
    total += shimmer * shimmer_mod

    # Evolving tone — rises slowly
    sweep_freq = 330 + 110 * t / dur
    total += np.sin(2 * np.pi * sweep_freq * t) * 0.04

    # Gentle sub bass
    total += np.sin(2 * np.pi * 55 * t) * 0.05

    # Emotional swell in the middle
    swell = np.sin(np.pi * t / dur) * 0.3 + 0.7
    total *= swell

    # Overall envelope
    total = envelope(total, attack=2.0, decay=1.0, sustain=0.8, release=4.0)

    save_wav("memory_vision_music.wav", total * 0.6, MUSIC_DIR)


def generate_title_theme():
    """Title screen theme — mysterious, inviting steampunk. 45s loop."""
    dur = 45.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    total = np.zeros(n)

    # Warm bass drone — D
    total += np.sin(2 * np.pi * 73.4 * t) * 0.06  # D2
    total += np.sin(2 * np.pi * 146.8 * t) * 0.04  # D3

    # Gentle arpeggiated pattern — Dm Am Bb F
    chords = [
        (146.8, 174.6, 220.0),   # Dm
        (220.0, 262.0, 330.0),   # Am
        (233.1, 293.7, 349.2),   # Bb
        (174.6, 220.0, 262.0),   # F
    ]
    chord_dur = dur / len(chords) / 3  # 3 repetitions
    for rep in range(3):
        for ci, (f1, f2, f3) in enumerate(chords):
            chord_start = (rep * len(chords) + ci) * chord_dur
            for ni, (freq, delay) in enumerate([(f1, 0), (f2, 0.3), (f3, 0.6)]):
                note_start = int((chord_start + delay) * SAMPLE_RATE)
                note_dur = chord_dur - delay
                note_n = int(note_dur * SAMPLE_RATE)
                if note_start + note_n > n:
                    note_n = n - note_start
                if note_n <= 0:
                    continue
                note_t = np.linspace(0, note_dur, note_n, endpoint=False)
                note = np.sin(2 * np.pi * freq * note_t) * 0.04
                note += np.sin(2 * np.pi * freq * 2 * note_t) * 0.015
                note *= np.exp(-note_t * 1.5)  # Natural decay
                total[note_start:note_start+note_n] += note[:note_n]

    # Atmospheric layer
    atmo = noise(dur) * 0.015
    atmo_mod = (np.sin(2 * np.pi * 0.04 * t) * 0.4 + 0.6)
    total += atmo * atmo_mod

    # Clockwork ticking — subtle
    for tick_time in np.arange(0, dur, 0.8):
        start = int(tick_time * SAMPLE_RATE)
        tick = sine(3000, 0.01) * 0.02
        tick = fade_out(tick, 0.008)
        end = min(start + len(tick), n)
        total[start:end] += tick[:end-start]

    # Crossfade
    xfade = int(2.0 * SAMPLE_RATE)
    total[-xfade:] *= np.linspace(1, 0, xfade)
    total[:xfade] *= np.linspace(0, 1, xfade)

    save_wav("title_theme.wav", total * 0.7, MUSIC_DIR)


# ============================================================
# MAIN
# ============================================================

if __name__ == "__main__":
    print("=== Generating Sound Effects ===\n")
    generate_pickup()
    generate_door()
    generate_dialogue_blip()
    generate_puzzle_solve()
    generate_steam_valve()
    generate_item_combine()
    generate_memory_vision()
    generate_footstep()
    generate_ui_click()
    generate_error_buzz()

    print("\n=== Generating Music ===\n")
    generate_harbor_ambient()
    generate_lighthouse_ambient()
    generate_bazaar_ambient()
    generate_memory_vision_music()
    generate_title_theme()

    print("\n=== Done! ===")
    print(f"SFX: {SFX_DIR}")
    print(f"Music: {MUSIC_DIR}")
