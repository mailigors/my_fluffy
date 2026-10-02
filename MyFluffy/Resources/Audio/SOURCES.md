# Audio sources

The current `.caf` cues use these recordings under the [Pixabay Content License](https://pixabay.com/service/license-summary/):

| Local source | Recording | Used for |
| --- | --- | --- |
| `pix_405457.wav` | [Kitten SFX](https://pixabay.com/sound-effects/nature-kitten-sfx-405457/) by DRAGON-STUDIO | `meow_01`, `meow_06` (different calls) |
| `pix_400946.wav` | [Cute Cat Meow](https://pixabay.com/sound-effects/nature-cute-cat-meow-400946/) by Virtual_Vibes | `meow_02`, `meow_04` (different calls) |
| `pix_472372.wav` | [Cute Cat Meow](https://pixabay.com/sound-effects/nature-cute-cat-meow-472372/) by DRAGON-STUDIO | `meow_03`, `mrr_meow` |
| `pix_14536.wav` | [Cat Meow](https://pixabay.com/sound-effects/nature-cat-meow-14536/) by freesound_community | `meow_05` |
| `pix_purr_68797.wav` | [Cat Purring](https://pixabay.com/sound-effects/nature-cat-purring-68797/) by freesound_community | `purr_loop`, beginning of `mrr_meow`; quiet `purr_loop` also plays during sleep |
| `pix_snore_262650.wav` | [Sound Effect - Cat Snoring](https://pixabay.com/sound-effects/nature-sound-effect-cat-snoring-262650/) by ScottishPerson | `snore_loop` is retained as an unused legacy cue |

The source WAV files are mono, 44.1 kHz working copies decoded from the MP3 files. `generate_audio.py` trims calls, removes low rumble and high hiss, gently lowers background between meows, and creates crossfaded loops. Run `python3 generate_audio.py` from the repository root to rebuild the cues.

Feeding uses the existing `mrr_meow` cat cue at a quieter volume.

`faucet_open.caf` and `water_loop.caf` are original procedural sounds created for the kitchen. The faucet now uses only smooth muted tones, without a noisy click. The water loop uses filtered noise and is crossfaded at its seam. `music_day.caf` is an original gentle music-box melody that loops across the start screen, room and kitchen at a low playback volume. Run `python3 tools/generate_kitchen_audio.py` to regenerate the faucet, water and music WAV sources. No third-party recording is used for these files.

`cooking_sizzle.caf` is a quiet original filtered frying loop with smooth small bubbles. It plays only while ingredients are frying in the green heat zone. The same generator script rebuilds it.
