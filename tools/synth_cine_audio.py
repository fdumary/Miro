#!/usr/bin/env python3
"""Synthesised placeholder audio for the cutscenes (numpy + ffmpeg only).

Writes assets/audio/cine/*.ogg. Every cue is deterministic (fixed seeds), so reruns
produce the same files. tools/generate_cine_sfx_elevenlabs.py can replace any of
these with ElevenLabs sound effects; the game loads whichever file is at the path.
Run: python3 tools/synth_cine_audio.py
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "cine")


def seconds(n):
    return int(n * RATE)


def band(signal, low=0.0, high=None):
    """Brick-wall band filter in the frequency domain with soft 10% edges."""
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(len(signal), 1 / RATE)
    gain = np.ones_like(freqs)
    if low > 0:
        gain *= np.clip((freqs - low * 0.9) / (low * 0.2 + 1e-9), 0, 1)
    if high:
        gain *= np.clip((high * 1.1 - freqs) / (high * 0.2), 0, 1)
    return np.fft.irfft(spectrum * gain, len(signal))


def brown(n, rng):
    x = np.cumsum(rng.standard_normal(n))
    x -= np.convolve(x, np.ones(2001) / 2001, mode="same")
    return x / (np.abs(x).max() + 1e-9)


def pink(n, rng):
    spectrum = np.fft.rfft(rng.standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    spectrum[1:] /= np.sqrt(freqs[1:])
    spectrum[0] = 0
    x = np.fft.irfft(spectrum, n)
    return x / (np.abs(x).max() + 1e-9)


def env_decay(n, tau, attack=0.005):
    t = np.arange(n) / RATE
    return np.minimum(1, t / attack) * np.exp(-t / tau)


def reverb(signal, length=2.5, mix=0.3, seed=9):
    rng = np.random.default_rng(seed)
    n = seconds(length)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / RATE / (length / 5))
    ir = band(ir, 200, 6000)
    size = len(signal) + n
    wet = np.fft.irfft(np.fft.rfft(signal, size) * np.fft.rfft(ir, size), size)[: len(signal)]
    wet /= np.abs(wet).max() + 1e-9
    return signal * (1 - mix) + wet * mix * np.abs(signal).max()


def loopable(signal, fade=1.0):
    """Crossfade the tail into the head so the file loops without a click."""
    f = seconds(fade)
    ramp = np.linspace(0, 1, f)
    head = signal[:f] * ramp + signal[-f:] * (1 - ramp)
    return np.concatenate([head, signal[f:-f]])


def save(name, signal, peak=0.89, stereo_width=0.0, seed=0):
    signal = np.asarray(signal, dtype=np.float64)
    signal = signal / (np.abs(signal).max() + 1e-9) * peak
    if stereo_width > 0:
        rng = np.random.default_rng(seed + 100)
        delay = int(RATE * 0.011)
        right = np.concatenate([np.zeros(delay), signal[:-delay]])
        left = signal
        data = np.stack([left, left * (1 - stereo_width) + right * stereo_width], axis=1)
    else:
        data = np.stack([signal, signal], axis=1)
    pcm = (np.clip(data, -1, 1) * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    target = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "5", target], check=True)
    os.unlink(path)
    print("wrote", os.path.relpath(target))


def rain(rng):
    n = seconds(9)
    hiss = band(pink(n, rng), 400, 9000) * 0.6
    drops = np.zeros(n)
    for _ in range(2600):
        at = rng.integers(0, n - 800)
        length = rng.integers(80, 500)
        drops[at : at + length] += rng.standard_normal(length) * np.exp(-np.arange(length) / (length / 5)) * rng.uniform(0.1, 0.6)
    drops = band(drops, 1500, 12000)
    patter = hiss + drops * 0.8
    swell = 0.85 + 0.15 * np.sin(np.arange(n) / RATE * 2 * np.pi * 0.23)
    return loopable(patter * swell)


def thunder(rng, near=True):
    n = seconds(7.5)
    out = np.zeros(n)
    if near:
        crack_n = seconds(0.35)
        crack = rng.standard_normal(crack_n) * env_decay(crack_n, 0.07, 0.001)
        out[:crack_n] += band(crack, 300, 9000) * 1.4
    start = 0.05 if near else 0.4
    for hit in range(7 if near else 5):
        at = seconds(start + hit * rng.uniform(0.25, 0.7))
        if at >= n:
            break
        length = n - at
        roll = brown(length, rng) * env_decay(length, rng.uniform(0.6, 1.6), 0.04 if near else 0.25)
        out[at:] += roll * (1.0 - hit * 0.09)
    out = band(out, 18, 2500 if near else 600)
    return reverb(out, 3.0, 0.35, seed=rng.integers(1, 99))


def explosion(rng):
    n = seconds(9)
    t = np.arange(n) / RATE
    # Sub-bass drop: 70 Hz falling to 28 Hz, long decay, softly clipped for weight.
    freq = 28 + 42 * np.exp(-t / 0.5)
    sub = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * env_decay(n, 2.4, 0.004)
    sub = np.tanh(sub * 2.2)
    blast = band(rng.standard_normal(n), 30, 1800) * env_decay(n, 0.45, 0.002)
    crack = band(rng.standard_normal(n), 1500, 9000) * env_decay(n, 0.05, 0.0005)
    rumble = brown(n, rng) * env_decay(n, 3.5, 0.3)
    rumble = band(rumble, 15, 160)
    debris = np.zeros(n)
    for _ in range(140):
        at = int(RATE * (0.25 + rng.exponential(0.9)))
        if at >= n - 3000:
            continue
        length = rng.integers(300, 2500)
        debris[at : at + length] += rng.standard_normal(length) * np.exp(-np.arange(length) / (length / 6)) * rng.uniform(0.05, 0.4) * np.exp(-at / RATE / 2.5)
    debris = band(debris, 400, 7000)
    mix = sub * 1.0 + blast * 0.9 + crack * 0.5 + rumble * 0.8 + debris * 0.5
    return reverb(mix, 3.5, 0.3, seed=4)


def rumble_loop(rng):
    n = seconds(6)
    r = band(brown(n, rng), 15, 110)
    wobble = 0.7 + 0.3 * np.sin(np.arange(n) / RATE * 2 * np.pi * 1.7) * np.sin(np.arange(n) / RATE * 2 * np.pi * 0.31)
    return loopable(r * wobble)


def fire_loop(rng):
    n = seconds(6)
    roar = band(pink(n, rng), 60, 1200) * (0.7 + 0.3 * np.sin(np.arange(n) / RATE * 2 * np.pi * 0.6))
    pops = np.zeros(n)
    for _ in range(420):
        at = rng.integers(0, n - 600)
        length = rng.integers(40, 400)
        pops[at : at + length] += rng.standard_normal(length) * np.exp(-np.arange(length) / (length / 4)) * rng.uniform(0.2, 1.0)
    pops = band(pops, 900, 9000)
    return loopable(roar * 0.8 + pops * 0.6)


def waves_loop(rng):
    n = seconds(12)
    t = np.arange(n) / RATE
    swell = np.clip(np.sin(2 * np.pi * t / 6.0 - 1.2), 0, 1) ** 1.6
    wash = band(pink(n, rng), 150, 5000) * (0.15 + 0.85 * swell)
    foam = band(rng.standard_normal(n), 3000, 11000) * np.clip(np.sin(2 * np.pi * t / 6.0 - 1.9), 0, 1) ** 3 * 0.25
    return loopable(wash + foam, 1.5)


def wind_loop(rng):
    n = seconds(10)
    t = np.arange(n) / RATE
    gust = 0.45 + 0.35 * np.sin(2 * np.pi * t / 5.0) + 0.2 * np.sin(2 * np.pi * t / 1.7 + 1)
    whistle = band(pink(n, rng), 250, 1400) * gust
    return loopable(whistle, 1.5)


def gulls(rng):
    n = seconds(3.5)
    out = np.zeros(n)
    for call in range(3):
        at = seconds(0.2 + call * rng.uniform(0.7, 1.0))
        length = seconds(rng.uniform(0.22, 0.38))
        t = np.arange(length) / RATE
        f = 2200 - 900 * (t / t[-1]) + 300 * np.sin(2 * np.pi * 9 * t)
        tone = np.sin(2 * np.pi * np.cumsum(f) / RATE) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / RATE)
        out[at : at + length] += tone * np.sin(np.pi * t / t[-1]) ** 1.5 * (0.8 - call * 0.2)
    return reverb(out, 1.5, 0.3, seed=12)


NOTE = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}


def hz(name, octave):
    return 440.0 * 2 ** ((NOTE[name] + 12 * (octave + 1) - 69) / 12)


def chords():
    """Slow, emotional progression in F major: Dm - Bb - F - C, then Dm - Bb - Gm - C (sus) - F.
    A soft pad holds each chord and a piano-like voice arpeggiates it. About 40 s, loopable."""
    rng = np.random.default_rng(31)
    bar = 4.8
    progression = [
        [("D", 3), ("A", 3), ("D", 4), ("F", 4), ("A", 4)],
        [("Bb", 2), ("F", 3), ("D", 4), ("F", 4), ("Bb", 4)],
        [("F", 2), ("C", 4), ("F", 4), ("A", 4), ("C", 5)],
        [("C", 3), ("G", 3), ("E", 4), ("G", 4), ("C", 5)],
        [("D", 3), ("A", 3), ("F", 4), ("A", 4), ("D", 5)],
        [("Bb", 2), ("F", 3), ("D", 4), ("F", 4), ("A", 4)],
        [("G", 2), ("D", 3), ("Bb", 3), ("D", 4), ("G", 4)],
        [("C", 3), ("G", 3), ("F", 4), ("G", 4), ("C", 5)],
    ]
    n = seconds(bar * len(progression) + 2)
    out = np.zeros(n)
    for index, chord in enumerate(progression):
        at = seconds(index * bar)
        length = seconds(bar + 1.6)
        t = np.arange(length) / RATE
        shape = np.minimum(1, t / 1.2) * np.clip((bar + 1.6 - t) / 1.6, 0, 1)
        for name, octave in chord:
            f = hz(name, octave)
            for detune in (-0.25, 0.0, 0.3):
                out[at : at + length] += np.sin(2 * np.pi * (f + detune) * t + rng.uniform(0, 6)) * shape * 0.06
        # Piano-like arpeggio: up through the chord, then the top note again.
        arp = chord[1:] + [chord[-2]]
        for step, (name, octave) in enumerate(arp):
            start = at + seconds(step * bar / len(arp))
            ln = seconds(2.6)
            tt = np.arange(ln) / RATE
            f = hz(name, octave + 1 if step == len(arp) - 1 else octave)
            voice = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(4 * np.pi * f * tt) * np.exp(-tt / 0.4) + 0.12 * np.sin(6 * np.pi * f * tt) * np.exp(-tt / 0.2))
            voice *= np.minimum(1, tt / 0.004) * np.exp(-tt / 0.9) * (0.32 if step else 0.4)
            end = min(n, start + ln)
            out[start:end] += voice[: end - start]
        # Bass root an octave down.
        f = hz(chord[0][0], chord[0][1] - 1)
        out[at : at + length] += np.sin(2 * np.pi * f * t) * shape * 0.18
    out = band(out, 30, 7000)
    out = reverb(out, 4.0, 0.42, seed=5)
    return loopable(out[: seconds(bar * len(progression) + 1.5)], 1.5)


def main():
    rng = np.random.default_rng(7)
    save("rain_loop", rain(rng), 0.7, 0.6)
    save("thunder_near", thunder(np.random.default_rng(11), True), 0.95, 0.5)
    save("thunder_far", thunder(np.random.default_rng(12), False), 0.9, 0.5)
    save("explosion_big", explosion(np.random.default_rng(13)), 0.97, 0.4)
    save("rumble_loop", rumble_loop(np.random.default_rng(14)), 0.9)
    save("fire_loop", fire_loop(np.random.default_rng(15)), 0.75, 0.5)
    save("waves_loop", waves_loop(np.random.default_rng(16)), 0.7, 0.7)
    save("wind_loop", wind_loop(np.random.default_rng(17)), 0.6, 0.7)
    save("gulls", gulls(np.random.default_rng(18)), 0.5, 0.4)
    # ending_chords.ogg is Ethan's own "emotional chord progression" (converted from his mp3);
    # chords() is the old placeholder, kept only for reference.


if __name__ == "__main__":
    main()
