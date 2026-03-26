#!/usr/bin/env python3
"""Split the spritesheet into individual frame PNGs for Godot."""
from PIL import Image
import os

ASSETS = os.path.expanduser("~/SteampunkBeachDemo/assets")

def split_character():
    """Split elara_spritesheet.png into individual frame images."""
    sheet = Image.open(os.path.join(ASSETS, "characters", "elara_spritesheet.png"))
    frame_w, frame_h = 32, 48
    frames_dir = os.path.join(ASSETS, "characters", "frames")
    os.makedirs(frames_dir, exist_ok=True)

    frame_map = {
        "idle_right_0": (0, 0), "idle_right_1": (1, 0),
        "idle_left_0": (2, 0), "idle_left_1": (3, 0),
        "walk_right_0": (0, 1), "walk_right_1": (1, 1),
        "walk_right_2": (2, 1), "walk_right_3": (3, 1),
        "walk_left_0": (0, 2), "walk_left_1": (1, 2),
        "walk_left_2": (2, 2), "walk_left_3": (3, 2),
        "talk_right_0": (0, 3), "talk_right_1": (1, 3),
        "talk_left_0": (2, 3), "talk_left_1": (3, 3),
    }

    for name, (col, row) in frame_map.items():
        x = col * frame_w
        y = row * frame_h
        frame = sheet.crop((x, y, x + frame_w, y + frame_h))
        frame.save(os.path.join(frames_dir, f"{name}.png"))
        print(f"  Saved: {name}.png")

def split_crab():
    """Split crab.png into individual frames."""
    sheet = Image.open(os.path.join(ASSETS, "props", "crab.png"))
    frames_dir = os.path.join(ASSETS, "props", "crab_frames")
    os.makedirs(frames_dir, exist_ok=True)

    # Frame 0: idle (0-23), Frame 1: retreat (24-47)
    idle = sheet.crop((0, 0, 24, 16))
    idle.save(os.path.join(frames_dir, "idle.png"))
    retreat = sheet.crop((24, 0, 48, 16))
    retreat.save(os.path.join(frames_dir, "retreat.png"))
    print("  Saved crab frames")

def split_capsule():
    """Split capsule.png into individual frames."""
    sheet = Image.open(os.path.join(ASSETS, "props", "capsule.png"))
    frames_dir = os.path.join(ASSETS, "props", "capsule_frames")
    os.makedirs(frames_dir, exist_ok=True)

    for i, name in enumerate(["closed", "keyhole", "open"]):
        frame = sheet.crop((i * 64, 0, (i + 1) * 64, 48))
        frame.save(os.path.join(frames_dir, f"{name}.png"))
        print(f"  Saved capsule: {name}.png")

if __name__ == "__main__":
    print("Splitting character spritesheet...")
    split_character()
    print("Splitting crab spritesheet...")
    split_crab()
    print("Splitting capsule spritesheet...")
    split_capsule()
    print("Done!")
