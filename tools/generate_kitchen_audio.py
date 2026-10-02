"""Create the original kitchen faucet, water cue and gentle daytime music.

Run from the repository root, then convert the WAV files with afconvert:
  python3 tools/generate_kitchen_audio.py
  afconvert -f caff -d LEI16 /private/tmp/fluffy-faucet.wav MyFluffy/Resources/Audio/faucet_open.caf
  afconvert -f caff -d LEI16 /private/tmp/fluffy-water.wav MyFluffy/Resources/Audio/water_loop.caf
  afconvert -f caff -d LEI16 /private/tmp/fluffy-sizzle.wav MyFluffy/Resources/Audio/cooking_sizzle.caf
  afconvert -f caff -d LEI16 /private/tmp/fluffy-music.wav MyFluffy/Resources/Audio/music_day.caf
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
TEMP = Path("/private/tmp")


def write_wave(name, samples, peak_limit, normalize=False):
    peak = max(abs(sample) for sample in samples)
    scale = peak_limit / peak if normalize else min(1.0, peak_limit / peak)
    with wave.open(str(TEMP / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1, min(1, sample * scale)) * 32767))
                for sample in samples
            )
        )


def faucet_open():
    # Rounded, muted handle movement with no noise burst or sharp attack.
    duration = 0.31
    samples = [0.0] * int(RATE * duration)
    for start, frequency, amplitude in ((0.015, 230, 0.12), (0.145, 185, 0.075)):
        span = 0.13
        for offset in range(int(RATE * span)):
            age = offset / RATE
            envelope = math.sin(math.pi * age / span) ** 2
            phase = 2 * math.pi * (frequency - 35 * age / span) * age
            index = int(start * RATE) + offset
            samples[index] += amplitude * envelope * math.sin(phase)
    write_wave("fluffy-faucet.wav", samples, 0.2)


def water_loop():
    random.seed(1248)
    seconds = 4.0
    overlap = 0.22
    count = int(RATE * (seconds + overlap))
    low = 0.0
    soft = 0.0
    samples = []
    for index in range(count):
        noise = random.uniform(-1, 1)
        low = low * 0.63 + noise * 0.37
        soft = soft * 0.72 + low * 0.28
        time = index / RATE
        ripple = 0.88 + 0.08 * math.sin(2 * math.pi * 0.47 * time)
        samples.append(0.17 * ripple * soft)

    # Small soft drops make the texture read as a trickle instead of white noise.
    for _ in range(29):
        start = random.randrange(count)
        frequency = random.uniform(460, 740)
        duration = int(RATE * 0.085)
        for offset in range(duration):
            index = start + offset
            if index >= count:
                break
            age = offset / RATE
            envelope = (1 - math.exp(-age * 180)) * math.exp(-age * 43)
            samples[index] += 0.025 * envelope * math.sin(2 * math.pi * frequency * age)

    loop_count = int(RATE * seconds)
    fade_count = int(RATE * overlap)
    for index in range(fade_count):
        amount = index / fade_count
        samples[index] = samples[loop_count + index] * (1 - amount) + samples[index] * amount
    write_wave("fluffy-water.wav", samples[:loop_count], 0.28)


def sizzle_loop():
    random.seed(2183)
    seconds = 3.6
    overlap = 0.2
    count = int(RATE * (seconds + overlap))
    smooth = 0.0
    samples = []
    for index in range(count):
        white = random.uniform(-1, 1)
        smooth = smooth * 0.45 + white * 0.55
        time = index / RATE
        swell = 0.78 + 0.16 * math.sin(2 * math.pi * 0.67 * time)
        samples.append(0.12 * smooth * swell)

    # Small bubbles, with smooth envelopes rather than abrupt crackles.
    for _ in range(35):
        begin = random.randrange(count)
        span = int(RATE * random.uniform(0.035, 0.065))
        frequency = random.uniform(700, 1100)
        for offset in range(span):
            index = begin + offset
            if index >= count:
                break
            phase = offset / span
            samples[index] += 0.025 * math.sin(math.pi * phase) ** 2 * math.sin(2 * math.pi * frequency * offset / RATE)

    loop_count = int(RATE * seconds)
    fade_count = int(RATE * overlap)
    for index in range(fade_count):
        amount = index / fade_count
        samples[index] = samples[loop_count + index] * (1 - amount) + samples[index] * amount
    write_wave("fluffy-sizzle.wav", samples[:loop_count], 0.3)


def music_loop():
    seconds = 24
    length = RATE * seconds
    samples = [0.0] * length

    def add_note(start, midi, amplitude, duration):
        frequency = 440 * 2 ** ((midi - 69) / 12)
        first = int(start * RATE)
        for offset in range(int(duration * RATE)):
            age = offset / RATE
            attack = 1 - math.exp(-age * 65)
            decay = math.exp(-age * (2.8 if midi >= 72 else 1.25))
            phase = 2 * math.pi * frequency * age
            tone = math.sin(phase) + 0.19 * math.sin(2 * phase) + 0.055 * math.sin(3 * phase)
            samples[(first + offset) % length] += amplitude * attack * decay * tone

    # Six short bars of a soft music-box melody. Ringing tails wrap at the seam.
    chords = [
        (48, 55, 60, [72, 76, 79, 76, 74, 72]),
        (43, 50, 59, [71, 74, 79, 74, 72, 71]),
        (45, 52, 60, [72, 76, 81, 76, 74, 72]),
        (41, 48, 57, [69, 72, 77, 72, 71, 69]),
        (50, 57, 62, [74, 77, 81, 77, 76, 74]),
        (43, 50, 59, [71, 74, 79, 74, 72, 71]),
    ]
    for bar, (root, fifth, third, melody) in enumerate(chords):
        begin = bar * 4
        for beat in (0, 2):
            add_note(begin + beat, root, 0.045, 2.8)
            add_note(begin + beat + 0.04, fifth, 0.025, 2.3)
            add_note(begin + beat + 0.08, third, 0.019, 2.0)
        for index, note in enumerate(melody):
            add_note(begin + index * 0.65, note, 0.052, 1.0)

    # A faint delayed copy softens the notes without adding percussion.
    delay = int(RATE * 0.17)
    original = samples[:]
    for index in range(length):
        samples[index] += 0.11 * original[(index - delay) % length]
    write_wave("fluffy-music.wav", samples, 0.34, normalize=True)


if __name__ == "__main__":
    faucet_open()
    water_loop()
    sizzle_loop()
    music_loop()
