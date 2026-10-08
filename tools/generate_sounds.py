"""Génère les sons de TowerTS dans assets/audio/ (fichiers .ogg).

Tout est synthétisé ici, sans banque de sons : modifier une ligne puis relancer
    python3 tools/generate_sounds.py
Nécessite Python 3 et ffmpeg (pour l'encodage Ogg Vorbis).
"""
import math, random, struct, wave, os, subprocess, tempfile
SR = 22050
random.seed(7)
OUT = tempfile.mkdtemp()
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")

def env_ad(t, a, d):
    if t < a: return t / a
    return max(0.0, 1.0 - (t - a) / d)

def write(name, samples, peak=0.85):
    m = max(1e-9, max(abs(x) for x in samples))
    k = peak / m
    path = f"{OUT}/{name}.wav"
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * k)) * 32767)) for x in samples))
    return path

def lowpass(samples, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff); dt = 1.0 / SR; a = dt / (rc + dt)
    out = []; y = 0.0
    for x in samples:
        y += a * (x - y); out.append(y)
    return out

def highpass(samples, cutoff):
    lp = lowpass(samples, cutoff)
    return [x - l for x, l in zip(samples, lp)]

def noise(n): return [random.uniform(-1, 1) for _ in range(n)]

def sweep(f0, f1, dur, wave_fn=math.sin, a=0.002, d=None, curve=1.0):
    n = int(dur * SR); d = d or dur; ph = 0.0; out = []
    for i in range(n):
        t = i / SR; p = (t / dur) ** curve
        f = f0 + (f1 - f0) * p
        ph += 2 * math.pi * f / SR
        out.append(wave_fn(ph) * env_ad(t, a, d))
    return out

def square(ph): return 1.0 if math.sin(ph) >= 0 else -1.0
def tri(ph): return 2 / math.pi * math.asin(math.sin(ph))
def mix(*tracks):
    n = max(len(t) for t in tracks); out = [0.0] * n
    for t in tracks:
        for i, x in enumerate(t): out[i] += x
    return out
def gain(t, g): return [x * g for x in t]
def pad(t, n): return t + [0.0] * (n - len(t))
def delay(t, sec): return [0.0] * int(sec * SR) + t
def shaped_noise(dur, cutoff, a, d):
    n = int(dur * SR)
    s = lowpass(noise(n), cutoff)
    return [x * env_ad(i / SR, a, d) for i, x in enumerate(s)]

def note(freq, dur, fn=square, vol=1.0, a=0.005, d=None):
    n = int(dur * SR); d = d or dur * 0.9; out = []
    for i in range(n):
        t = i / SR
        out.append(fn(2 * math.pi * freq * t) * env_ad(t, a, d) * vol)
    return out

def seq(notes, fn=square, step=0.08, vol=1.0, length=None):
    out = []
    for f in notes:
        out += note(f, step, fn, vol) if f else [0.0] * int(step * SR)
    return out

def hz(semi): return 440.0 * 2 ** (semi / 12)  # 0 = la4

files = []
# Tirs
files.append(write("shot_cannon", mix(sweep(220, 60, 0.18, math.sin, d=0.18), gain(shaped_noise(0.12, 2500, 0.001, 0.1), 0.6))))
files.append(write("shot_gatling", mix(gain(highpass(shaped_noise(0.05, 6000, 0.0005, 0.045), 800), 1.0), gain(sweep(900, 400, 0.04, square, d=0.04), 0.25)), 0.6))
files.append(write("shot_sniper", mix(gain(highpass(shaped_noise(0.25, 9000, 0.0005, 0.22), 1500), 1.0), gain(sweep(1600, 200, 0.12, math.sin, d=0.12), 0.5))))
files.append(write("shot_mortar", mix(sweep(140, 50, 0.3, math.sin, d=0.3), gain(shaped_noise(0.2, 900, 0.002, 0.18), 0.7))))
files.append(write("explosion", mix(gain(shaped_noise(0.7, 1200, 0.002, 0.65), 1.0), sweep(90, 30, 0.5, math.sin, d=0.5))))
shimmer = mix(*[gain(sweep(f, f * 1.5, 0.45, math.sin, a=0.01, d=0.44), 0.4) for f in (1046, 1318, 1568, 2093)])
files.append(write("pulse_frost", mix(shimmer, gain(highpass(shaped_noise(0.4, 8000, 0.01, 0.38), 3000), 0.4)), 0.6))
files.append(write("beam_zap", mix(gain(sweep(1200, 1500, 0.07, square, d=0.07), 0.3), gain(sweep(600, 750, 0.07, math.sin, d=0.07), 0.7)), 0.45))
# Ennemis et vies
files.append(write("enemy_death", mix(sweep(600, 120, 0.14, math.sin, d=0.14, curve=0.5), gain(shaped_noise(0.08, 3000, 0.001, 0.07), 0.3))))
files.append(write("enemy_split", mix(sweep(300, 900, 0.18, tri, d=0.18), gain(delay(sweep(400, 1100, 0.14, tri, d=0.14), 0.06), 0.7))))
files.append(write("lives_lost", mix(gain(note(hz(-33), 0.45, square, 1, 0.005, 0.43), 0.6), gain(note(hz(-32), 0.45, square, 1, 0.005, 0.43), 0.6))))
# Interface et économie
files.append(write("build", mix(sweep(180, 90, 0.12, math.sin, d=0.12), gain(delay(note(hz(3), 0.12, tri), 0.04), 0.5))))
files.append(write("upgrade", seq([hz(3), hz(7), hz(10), hz(15)], tri, 0.07)))
files.append(write("sell", mix(seq([hz(19), hz(24)], square, 0.06, 0.5), gain(delay(seq([hz(22), hz(27)], square, 0.06, 0.5), 0.03), 0.6))))
files.append(write("coins", seq([hz(15), hz(22), hz(27)], square, 0.05, 0.6)))
files.append(write("wave_start", mix(gain(note(hz(-5), 0.5, square, 1, 0.03, 0.45), 0.5), gain(note(hz(-1), 0.5, square, 1, 0.03, 0.45), 0.4), gain(note(hz(2), 0.5, tri, 1, 0.03, 0.45), 0.6))))
files.append(write("victory", seq([hz(3), hz(7), hz(10), hz(15), None, hz(10), hz(15), hz(15), hz(15)], square, 0.12, 0.8)))
files.append(write("defeat", seq([hz(3), hz(2), hz(1), hz(0), hz(-1), hz(-2), hz(-6), hz(-6), hz(-6)], tri, 0.16)))

# Musique : boucle chiptune en la mineur, 8 mesures à 112 bpm.
bpm = 112; beat = 60 / bpm; bars = 8
total = int(bars * 4 * beat * SR)
chords = [(-12, [0, 3, 7]), (-16, [-4, 0, 3]), (-19, [-7, -3, 0]), (-14, [-2, 2, 5]),
          (-12, [0, 3, 7]), (-16, [-4, 0, 3]), (-21, [-9, -5, -2]), (-17, [-5, -1, 2])]
music = [0.0] * total
def add(track, start):
    s = int(start * SR)
    for i, x in enumerate(track):
        if s + i < total: music[s + i] += x
for bar, (root, chord) in enumerate(chords):
    t0 = bar * 4 * beat
    for b in range(4):  # basse en croches
        for h in range(2):
            f = hz(root - 12 + (7 if h == 1 and b % 2 == 1 else 0))
            add(gain(note(f, beat / 2, tri, 1, 0.005, beat / 2 * 0.8), 0.55), t0 + b * beat + h * beat / 2)
    for s16 in range(16):  # arpège en doubles croches
        f = hz(chord[s16 % 3] + 12 * (s16 // 3 % 2))
        add(gain(note(f, beat / 4, square, 1, 0.002, beat / 4 * 0.7), 0.12), t0 + s16 * beat / 4)
    for b in range(4):  # charleston
        add(gain(highpass(shaped_noise(0.05, 9000, 0.001, 0.04), 4000), 0.25), t0 + b * beat + beat / 2)
        if b % 2 == 0:
            add(gain(sweep(150, 50, 0.12, math.sin, d=0.12), 0.6), t0 + b * beat)
melody = [7, None, 10, 12, 10, None, 7, 5, 3, None, 5, 7, 3, None, None, None,
          0, None, 3, 5, 7, None, 5, 3, 2, None, 3, 5, 2, None, None, None]
for i, m in enumerate(melody * 2):
    if m is not None:
        add(gain(note(hz(m), beat * 0.9, tri, 1, 0.01, beat * 0.8), 0.22), i * beat)
# La musique du jeu vient maintenant des boucles de Kenney (assets/audio/musique/) : elle
# n'est plus écrite, mais reste calculée pour ne pas changer le tirage des sons suivants.

# Tours ajoutées après la musique (pour ne pas changer le tirage des sons précédents)
crackle = gain(highpass(shaped_noise(0.16, 9000, 0.0005, 0.15), 2500), 0.8)
files.append(write("arc_zap", mix(crackle, gain(sweep(2400, 700, 0.12, square, d=0.12), 0.25),
    gain(delay(highpass(shaped_noise(0.08, 9000, 0.0005, 0.07), 3000), 0.05), 0.6)), 0.55))
files.append(write("coil_hum", mix(gain(note(hz(-24), 0.3, square, 1, 0.02, 0.28), 0.4),
    gain(note(hz(-12), 0.3, tri, 1, 0.02, 0.28), 0.6)), 0.4))
files.append(write("magnet_pulse", mix(sweep(900, 140, 0.35, math.sin, a=0.01, d=0.34, curve=0.6),
    gain(sweep(450, 70, 0.35, tri, a=0.01, d=0.34), 0.5)), 0.6))

os.makedirs(DEST, exist_ok=True)
for f in files:
    name = os.path.basename(f)[:-4]
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", f, "-c:a", "libvorbis", "-q:a", "4",
                    os.path.join(DEST, f"{name}.ogg")], check=True)
print(f"{len(files)} sons écrits dans {os.path.normpath(DEST)}")
