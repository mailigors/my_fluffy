"""Generate original, quiet game cues. Run from the repository root."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
DEST = Path("MyFluffy/Resources/Audio")
TEMP = Path("/private/tmp")


def tone(notes, duration):
    samples = [0.0] * int(RATE * duration)
    for start, pitch, span, level in notes:
        for offset in range(int(RATE * span)):
            index = int(start * RATE) + offset
            if index >= len(samples):
                break
            t = offset / RATE
            envelope = min(1, t * 75) * math.exp(-t * 7 / span)
            samples[index] += level * envelope * (
                math.sin(2 * math.pi * pitch * t)
                + 0.14 * math.sin(2 * math.pi * pitch * 2 * t)
            )
    return samples


def flush():
    random.seed(84)
    count = int(RATE * 0.9)
    samples = []
    smooth = 0.0
    for index in range(count):
        t = index / RATE
        smooth = smooth * 0.87 + random.uniform(-1, 1) * 0.13
        envelope = math.sin(math.pi * t / 0.9) ** 2
        samples.append(0.12 * smooth * envelope + 0.025 * envelope * math.sin(2 * math.pi * (190 - 90 * t) * t))
    peak = max(abs(value) for value in samples)
    return [value * (0.28 / peak) for value in samples]


def save(name, samples):
    path = TEMP / f"{name}.wav"
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, value)) * 32767)) for value in samples))
    return path


if __name__ == "__main__":
    cues = {
        "game_fish": ([(0, 390, 0.24, 0.28), (0.08, 530, 0.22, 0.18)], 0.34),
        "game_gold": ([(0, 520, 0.28, 0.22), (0.10, 660, 0.28, 0.22), (0.22, 880, 0.30, 0.19)], 0.6),
        "game_jump": ([(0, 290, 0.34, 0.28), (0.10, 440, 0.28, 0.18)], 0.46),
        "game_miss": ([(0, 300, 0.30, 0.18), (0.10, 230, 0.24, 0.14)], 0.42),
        "game_select": ([(0, 560, 0.18, 0.20)], 0.22),
        "game_match": ([(0, 480, 0.22, 0.20), (0.10, 720, 0.25, 0.20)], 0.43),
        "game_move": ([(0, 340, 0.20, 0.18), (0.07, 410, 0.18, 0.12)], 0.32),
        "game_hit": ([(0, 270, 0.20, 0.30), (0.06, 400, 0.18, 0.12)], 0.31),
        "game_win": ([(0, 500, 0.34, 0.20), (0.15, 630, 0.36, 0.20), (0.31, 800, 0.44, 0.20)], 0.82),
        "game_lose": ([(0, 370, 0.30, 0.16), (0.18, 290, 0.34, 0.14)], 0.56),
        "game_hockey_hit": ([(0, 230, 0.18, 0.27), (0.035, 310, 0.16, 0.12)], 0.24),
        "game_hockey_goal": ([(0, 440, 0.22, 0.19), (0.10, 580, 0.24, 0.18), (0.23, 760, 0.30, 0.16)], 0.58),
        "game_toy_shot": ([(0, 310, 0.17, 0.17), (0.035, 420, 0.14, 0.11)], 0.24),
        "game_toy_pop": ([(0, 570, 0.17, 0.24), (0.045, 710, 0.18, 0.14)], 0.28),
    }
    for name, (notes, duration) in cues.items():
        save(name, tone(notes, duration))
    save("game_flush", flush())
