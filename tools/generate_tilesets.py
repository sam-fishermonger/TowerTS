#!/usr/bin/env python3
"""Dessine les tuiles de décor des quatre biomes : assets/sprites/tiles/<biome>.png.

Chaque image est une planche de 8 x 3 tuiles de 64 pixels, lue par les TileSet de
resources/tilesets/ et par GameMap :

- rang 0 : 8 variantes du sol, en niveaux de gris (le jeu les teinte avec la couleur
  du sol du niveau, ground_color). Les 4 premières sont les plus fréquentes ;
- rang 1 : 8 détails posés sur le sol, en couleur et transparents (œufs, flaques,
  boulons, herbes…) ;
- rang 2 : 4 obstacles pour les cases bloquées, en gris (teintés avec rock_color),
  puis 4 petits détails semés sur le chemin (cailloux, fissures, taches).

Python 3 avec Pillow et numpy. Relancer le script réécrit les images (toutes, ou
seulement celles des biomes donnés) :

    python3 tools/generate_tilesets.py
    python3 tools/generate_tilesets.py undead
"""

import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TILE = 64
# Dessin en 4x puis réduction : bords lissés.
SCALE = 4
T = TILE * SCALE
COLUMNS = 8
ROWS = 3
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "tiles")


# --- Outils -------------------------------------------------------------------

def tileable_noise(rng, size, cells, octaves=3):
    """Bruit lisse qui se raccorde à lui-même sur les bords (valeurs 0..1)."""
    result = np.zeros((size, size))
    amplitude = 1.0
    total = 0.0
    for octave in range(octaves):
        n = cells * 2 ** octave
        grid = rng.random((n, n))
        coords = np.arange(size) * n / size
        i0 = np.floor(coords).astype(int)
        frac = coords - i0
        frac = frac * frac * (3 - 2 * frac)
        i1 = (i0 + 1) % n
        i0 %= n
        top = grid[i0][:, i0] * (1 - frac)[None, :] + grid[i0][:, i1] * frac[None, :]
        bottom = grid[i1][:, i0] * (1 - frac)[None, :] + grid[i1][:, i1] * frac[None, :]
        layer = top * (1 - frac)[:, None] + bottom * frac[:, None]
        result += layer * amplitude
        total += amplitude
        amplitude *= 0.5
    return result / total


def edge_mask(size, margin):
    """1 au centre, 0 sur les bords : ce qui est propre à une variante ne touche pas les voisines."""
    ramp = np.clip(np.minimum(np.arange(size), size - 1 - np.arange(size)) / margin, 0, 1)
    ramp = ramp * ramp * (3 - 2 * ramp)
    return np.minimum(ramp[:, None], ramp[None, :])


def gray_image(values):
    """Tableau 0..1 -> image RGBA opaque en niveaux de gris."""
    v = (np.clip(values, 0, 1) * 255).astype(np.uint8)
    rgba = np.stack([v, v, v, np.full_like(v, 255)], axis=-1)
    return Image.fromarray(rgba, "RGBA")


def layer():
    return Image.new("RGBA", (T, T), (0, 0, 0, 0))


def s(value):
    """Coordonnée en pixels de tuile (0..64) -> pixels du dessin agrandi."""
    return value * SCALE


def ellipse(draw, cx, cy, rx, ry, fill, outline=None, width=0):
    draw.ellipse([s(cx - rx), s(cy - ry), s(cx + rx), s(cy + ry)], fill=fill, outline=outline,
                 width=int(s(width)))


def line(draw, points, fill, width):
    draw.line([(s(x), s(y)) for x, y in points], fill=fill, width=int(s(width)), joint="curve")
    for x, y in (points[0], points[-1]):
        ellipse(draw, x, y, width / 2, width / 2, fill)


def polygon(draw, points, fill, outline=None, width=0):
    draw.polygon([(s(x), s(y)) for x, y in points], fill=fill, outline=outline,
                 width=int(s(width)) if outline else 0)


def rect(draw, x0, y0, x1, y1, fill, outline=None, width=0, radius=0):
    draw.rounded_rectangle([s(x0), s(y0), s(x1), s(y1)], radius=s(radius), fill=fill, outline=outline,
                           width=int(s(width)))


def soft_shadow(image, offset=(1.5, 2.5), blur=2.5, alpha=0.45):
    """Ombre portée douce sous ce qui est dessiné (objets posés au sol)."""
    a = np.array(image)[:, :, 3].astype(float) * alpha
    shadow = Image.fromarray(np.zeros((T, T, 4), dtype=np.uint8), "RGBA")
    mask = Image.fromarray(a.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(s(blur)))
    shadow.putalpha(mask)
    out = layer()
    out.alpha_composite(shadow, (int(s(offset[0])), int(s(offset[1]))))
    out.alpha_composite(image)
    return out


def shrink(image):
    return image.resize((TILE, TILE), Image.LANCZOS)


# --- Sols -------------------------------------------------------------------

def hive_grounds(rng):
    """La Ruche : un sol organique en cellules (comme des alvéoles écrasées), avec des
    bosses, des pores et des veines au milieu de certaines variantes."""
    base_noise = tileable_noise(rng, T, 3, 4)
    # Cellules de Voronoï qui se raccordent : les points sont répétés autour de la tuile.
    points = rng.random((9, 2)) * T
    yy, xx = np.mgrid[0:T, 0:T]
    d1 = np.full((T, T), 1e9)
    d2 = np.full((T, T), 1e9)
    for px, py in points:
        for ox in (-T, 0, T):
            for oy in (-T, 0, T):
                d = np.hypot(xx - px - ox, yy - py - oy)
                d2 = np.where(d < d1, d1, np.minimum(d2, d))
                d1 = np.minimum(d1, d)
    walls = np.clip((d2 - d1) / s(3.0), 0, 1)
    base = 0.86 + 0.1 * base_noise - 0.13 * (1 - walls)
    mask = edge_mask(T, s(14))
    grounds = []
    for variant in range(COLUMNS):
        detail = np.zeros((T, T))
        local = np.random.default_rng(100 + variant)
        if variant in (1, 5):
            # Bosses rondes.
            for _ in range(3 if variant == 1 else 5):
                cx, cy = local.uniform(s(16), s(48), 2)
                r = local.uniform(s(4), s(9))
                d = np.hypot(xx - cx, yy - cy) / r
                detail += np.clip(1 - d, 0, 1) ** 0.7 * 0.12 - np.clip(1.25 - d, 0, 0.25) * 0.2 * (d > 1)
        if variant in (2, 6):
            # Pores sombres.
            for _ in range(6):
                cx, cy = local.uniform(s(14), s(50), 2)
                r = local.uniform(s(1.2), s(2.5))
                detail -= np.clip(1.6 - np.hypot(xx - cx, yy - cy) / r, 0, 1) * 0.3
        if variant in (3, 7):
            # Veines.
            vein = tileable_noise(local, T, 2, 2)
            detail -= np.clip(1 - np.abs(vein - 0.5) / 0.025, 0, 1) * 0.16
        if variant == 4:
            detail += (tileable_noise(local, T, 6, 2) - 0.5) * 0.12
        grounds.append(gray_image(base + detail * mask))
    return grounds


def foundry_grounds(rng):
    """La Fonderie : des plaques de métal rivetées, une par tuile, avec des joints sur les
    bords : tôle striée, grille, plaque usée ou rouillée selon la variante."""
    grounds = []
    yy, xx = np.mgrid[0:T, 0:T]
    for variant in range(COLUMNS):
        local = np.random.default_rng(200 + variant)
        brushed = tileable_noise(local, T, 2, 2) * 0.05 + local.random((T, T)) * 0.02
        values = 0.84 + brushed
        # Biseau : haut et gauche clairs, bas et droite sombres, joint sombre au bord.
        edge = np.minimum(np.minimum(xx, yy), np.minimum(T - 1 - xx, T - 1 - yy))
        values = np.where(edge < s(1.2), 0.5, values)
        values = np.where((edge >= s(1.2)) & (edge < s(3)) & ((xx < s(4)) | (yy < s(4))), values + 0.08, values)
        values = np.where((edge >= s(1.2)) & (edge < s(3)) & ((xx > T - s(4)) | (yy > T - s(4))), values - 0.1, values)
        if variant in (1, 5):
            # Tôle striée : petits reliefs en diagonale, alternés.
            u = (xx % s(10)) - s(5)
            v = (yy % s(10)) - s(5)
            flip = ((xx // s(10) + yy // s(10)) % 2) * 2 - 1
            ridge = np.abs(u - flip * v) < s(1.2)
            ridge &= np.abs(u + flip * v) < s(5)
            values = np.where(ridge & (edge > s(4)), values + 0.09, values)
        if variant == 2:
            # Grille d'aération.
            inside = (xx > s(12)) & (xx < s(52)) & (yy > s(12)) & (yy < s(52))
            slot = ((yy - s(12)) % s(6)) < s(3)
            values = np.where(inside, np.where(slot, 0.42, 0.78), values)
            frame = (np.abs(xx - s(32)) < s(21)) & (np.abs(yy - s(32)) < s(21)) & ~inside
            values = np.where(frame, values - 0.1, values)
        if variant in (3, 7):
            # Usure : taches et rayures.
            stain = tileable_noise(local, T, 3, 3)
            values -= np.clip(stain - 0.55, 0, 1) * 0.5
            for _ in range(4):
                x0, y0 = local.uniform(s(8), s(56), 2)
                angle = local.uniform(0, math.pi)
                length = local.uniform(s(8), s(20))
                t = np.clip(((xx - x0) * math.cos(angle) + (yy - y0) * math.sin(angle)) / length, 0, 1)
                d = np.hypot(xx - x0 - t * length * math.cos(angle), yy - y0 - t * length * math.sin(angle))
                values = np.where(d < s(0.5), values + 0.1, values)
        if variant == 6:
            # Plaque centrale boulonnée, plus sombre.
            inside = (np.abs(xx - s(32)) < s(16)) & (np.abs(yy - s(32)) < s(16))
            values = np.where(inside, values - 0.08, values)
            values = np.where(inside & ((np.abs(xx - s(32)) > s(14.5)) | (np.abs(yy - s(32)) > s(14.5))), values - 0.12, values)
        # Rivets aux coins.
        for cx, cy in ((7, 7), (57, 7), (7, 57), (57, 57)):
            d = np.hypot(xx - s(cx), yy - s(cy))
            values = np.where(d < s(2.2), 0.62 + 0.3 * np.clip((s(cy) - yy + s(2)) / s(4), 0, 1), values)
        grounds.append(gray_image(values))
    return grounds


def city_grounds(rng):
    """La Cité : des dalles (4 par tuile) ou des pavés, séparés par des joints sombres :
    dalle fendue, pavés, joints envahis d'herbe selon la variante."""
    grounds = []
    yy, xx = np.mgrid[0:T, 0:T]
    for variant in range(COLUMNS):
        local = np.random.default_rng(300 + variant)
        values = np.full((T, T), 0.9) + (tileable_noise(local, T, 4, 3) - 0.5) * 0.08
        if variant in (2, 6):
            # Pavés en quinconce, plus petits.
            row = yy // s(16)
            shifted = (xx + (row % 2) * s(8)) % s(16)
            joint = (shifted < s(1.5)) | ((yy % s(16)) < s(1.5))
            stone = local.random((T // s(16) + 1, T // s(16) + 2))
            tint = stone[row, (xx + (row % 2) * s(8)) // s(16) % stone.shape[1]] * 0.1 - 0.05
            values = values + tint
            values = np.where(joint, 0.58, values)
        else:
            # 4 dalles de 32 pixels, chacune un peu plus claire ou plus sombre.
            slab = local.random((2, 2)) * 0.08 - 0.04
            values = values + slab[yy // s(32), xx // s(32)]
            joint = ((xx % s(32)) < s(1.5)) | ((yy % s(32)) < s(1.5))
            values = np.where(joint, 0.6, values)
            # Arête claire en haut à gauche de chaque dalle.
            values = np.where(~joint & (((xx % s(32)) < s(3)) | ((yy % s(32)) < s(3))), values + 0.04, values)
        if variant in (1, 5):
            # Fissure.
            img = gray_image(values)
            draw = ImageDraw.Draw(img)
            x, y = local.uniform(8, 24), local.uniform(8, 24)
            points = [(x, y)]
            for _ in range(5):
                x += local.uniform(3, 8)
                y += local.uniform(-2, 7)
                points.append((x, y))
            line(draw, points, (110, 110, 110, 255), 1.0)
            values = np.array(img)[:, :, 0] / 255.0
        if variant in (3, 7):
            # Usure : les dalles sont plus sombres par endroits.
            values -= np.clip(tileable_noise(local, T, 3, 2) - 0.6, 0, 1) * 0.4
        grounds.append(gray_image(values))
    return grounds


def necropolis_grounds(rng):
    """La Nécropole : une terre sèche et craquelée, parfois des dalles funéraires
    usées ou de la mousse, selon la variante."""
    grounds = []
    yy, xx = np.mgrid[0:T, 0:T]
    for variant in range(COLUMNS):
        local = np.random.default_rng(400 + variant)
        values = np.full((T, T), 0.82) + (tileable_noise(local, T, 5, 3) - 0.5) * 0.16
        if variant in (2, 6):
            # Dalle funéraire au milieu de la tuile, bords usés.
            inside = (np.abs(xx - T / 2) < s(22)) & (np.abs(yy - T / 2) < s(26))
            border = inside & ((np.abs(xx - T / 2) > s(19.5)) | (np.abs(yy - T / 2) > s(23.5)))
            values = np.where(inside, 0.88 + (tileable_noise(local, T, 3, 2) - 0.5) * 0.06, values)
            values = np.where(border, 0.74, values)
        img = gray_image(values)
        draw = ImageDraw.Draw(img)
        # Craquelures de terre sèche, loin des bords pour que les tuiles se raccordent.
        for _ in range(3 if variant in (1, 5, 7) else 1):
            x, y = local.uniform(12, 52), local.uniform(12, 52)
            points = [(x, y)]
            for _ in range(4):
                x = float(np.clip(x + local.uniform(-7, 7), 6, 58))
                y = float(np.clip(y + local.uniform(-7, 7), 6, 58))
                points.append((x, y))
            line(draw, points, (120, 120, 120, 255), 0.8)
        values = np.array(img)[:, :, 0] / 255.0
        if variant in (3, 7):
            # Mousse sombre par plaques.
            values -= np.clip(tileable_noise(local, T, 3, 2) - 0.55, 0, 1) * 0.5 * edge_mask(T, s(8))
        grounds.append(gray_image(values))
    return grounds


# --- Détails du sol (en couleur) ------------------------------------------------

def hive_decals():
    decals = []
    # 0 : grappe d'œufs.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((28, 30, 6), (37, 27, 5.5), (33, 37, 5.5), (24, 39, 4.5), (41, 36, 4)):
        ellipse(d, cx, cy, r, r * 1.2, (232, 222, 170, 255), (120, 100, 60, 255), 0.8)
        ellipse(d, cx - r * 0.3, cy - r * 0.45, r * 0.3, r * 0.35, (255, 252, 230, 220))
    decals.append(soft_shadow(img))
    # 1 : flaque de bave verte.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 33, 15, 9, (120, 200, 60, 120))
    ellipse(d, 22, 28, 6, 4, (120, 200, 60, 110))
    ellipse(d, 42, 38, 5, 3.5, (120, 200, 60, 110))
    ellipse(d, 29, 31, 5, 2.5, (210, 255, 160, 120))
    decals.append(img)
    # 2 : racines sombres.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(8, 40), (20, 36), (30, 38), (44, 30), (56, 28)], (40, 25, 35, 150), 2.2)
    line(d, [(20, 36), (24, 26), (22, 16)], (40, 25, 35, 130), 1.5)
    line(d, [(30, 38), (34, 48), (40, 54)], (40, 25, 35, 130), 1.5)
    decals.append(img)
    # 3 : champignons violets.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((26, 34, 5), (35, 30, 6.5), (38, 40, 4)):
        rect(d, cx - r * 0.25, cy, cx + r * 0.25, cy + r * 1.1, (220, 210, 190, 255))
        ellipse(d, cx, cy, r, r * 0.7, (150, 80, 170, 255), (70, 30, 80, 255), 0.7)
        ellipse(d, cx - r * 0.35, cy - r * 0.2, r * 0.2, r * 0.15, (240, 220, 250, 230))
    decals.append(soft_shadow(img))
    # 4 : carapace et os.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(18, 40), (40, 26)], (225, 220, 200, 255), 2.5)
    ellipse(d, 17, 41, 2.6, 2.6, (225, 220, 200, 255)); ellipse(d, 41, 25, 2.6, 2.6, (225, 220, 200, 255))
    polygon(d, [(36, 40), (48, 36), (50, 44), (40, 48)], (90, 60, 90, 255), (40, 20, 40, 255), 0.7)
    decals.append(soft_shadow(img, blur=1.5))
    # 5 : terriers.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((24, 30, 5), (40, 38, 4)):
        ellipse(d, cx, cy + 1, r + 2, r * 0.8 + 2, (90, 70, 60, 110))
        ellipse(d, cx, cy, r, r * 0.7, (20, 12, 15, 230))
    decals.append(img)
    # 6 : gouttes de résine ambrée.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((26, 28, 4), (36, 34, 5), (30, 42, 3), (43, 26, 2.5)):
        ellipse(d, cx, cy, r, r, (230, 150, 40, 210), (140, 70, 10, 230), 0.6)
        ellipse(d, cx - r * 0.35, cy - r * 0.35, r * 0.3, r * 0.3, (255, 230, 170, 230))
    decals.append(img)
    # 7 : mousse sombre.
    img = layer(); d = ImageDraw.Draw(img)
    rng = random.Random(7)
    for _ in range(26):
        ellipse(d, rng.uniform(16, 48), rng.uniform(18, 46), rng.uniform(2, 4.5), rng.uniform(2, 4),
                (40, 90, 50, 70))
    decals.append(img)
    return decals


def foundry_decals():
    decals = []
    # 0 : tache d'huile.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 32, 14, 10, (15, 15, 20, 120))
    ellipse(d, 24, 38, 6, 4, (15, 15, 20, 110))
    ellipse(d, 30, 29, 6, 3, (90, 60, 140, 60))
    ellipse(d, 35, 33, 4, 2, (40, 120, 140, 60))
    decals.append(img)
    # 1 : boulons et écrous.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, angle in ((24, 30, 0.2), (38, 26, 0.9), (34, 40, 0.5)):
        hexagon = [(cx + 3.6 * math.cos(angle + k * math.pi / 3), cy + 3.6 * math.sin(angle + k * math.pi / 3))
                   for k in range(6)]
        polygon(d, hexagon, (175, 175, 180, 255), (70, 70, 75, 255), 0.6)
        ellipse(d, cx, cy, 1.4, 1.4, (60, 60, 65, 255))
    line(d, [(42, 36), (49, 41)], (160, 160, 165, 255), 1.8)
    decals.append(soft_shadow(img, blur=1.2))
    # 2 : câble.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(4, 20), (16, 24), (26, 34), (38, 36), (50, 30), (60, 34)], (30, 30, 35, 255), 2.6)
    line(d, [(4, 20), (16, 24), (26, 34), (38, 36), (50, 30), (60, 34)], (200, 60, 50, 255), 1.0)
    decals.append(soft_shadow(img, blur=1.2))
    # 3 : bouche d'aération ronde.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 32, 12, 12, (55, 58, 62, 255), (25, 25, 30, 255), 1.0)
    for k in range(6):
        a = k * math.pi / 3
        line(d, [(32, 32), (32 + 10 * math.cos(a), 32 + 10 * math.sin(a))], (120, 125, 130, 255), 1.6)
    ellipse(d, 32, 32, 3, 3, (130, 135, 140, 255))
    decals.append(img)
    # 4 : bandes de danger.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 14, 26, 50, 38, (230, 190, 40, 230), (40, 35, 20, 255), 0.8, 1.5)
    for k in range(5):
        x = 16 + k * 7.5
        polygon(d, [(x, 37), (x + 4, 27), (x + 7, 27), (x + 3, 37)], (30, 30, 30, 230))
    decals.append(img)
    # 5 : rouage abandonné.
    img = layer(); d = ImageDraw.Draw(img)
    teeth = []
    for k in range(20):
        a = k * math.pi / 10
        r = 10 if k % 2 == 0 else 7.5
        teeth.append((32 + r * math.cos(a), 32 + r * math.sin(a)))
    polygon(d, teeth, (150, 120, 90, 255), (60, 45, 35, 255), 0.7)
    ellipse(d, 32, 32, 3, 3, (60, 45, 35, 255))
    decals.append(soft_shadow(img, blur=1.5))
    # 6 : rouille.
    img = layer(); d = ImageDraw.Draw(img)
    rng = random.Random(6)
    for _ in range(18):
        ellipse(d, rng.uniform(18, 46), rng.uniform(18, 46), rng.uniform(2, 6), rng.uniform(2, 5),
                (170, 80, 30, 55))
    decals.append(img)
    # 7 : trace de brûlure.
    img = layer(); d = ImageDraw.Draw(img)
    for r, alpha in ((14, 40), (10, 60), (6, 90)):
        ellipse(d, 32, 32, r, r * 0.85, (10, 8, 8, alpha))
    decals.append(img)
    return decals


def city_decals():
    decals = []
    # 0 : touffes d'herbe.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy in ((24, 38), (38, 30), (34, 42)):
        for k in range(7):
            a = -math.pi / 2 + (k - 3) * 0.28
            line(d, [(cx, cy), (cx + 7 * math.cos(a), cy + 8 * math.sin(a))], (70, 140, 60, 255), 1.1)
    decals.append(soft_shadow(img, blur=1.0, alpha=0.3))
    # 1 : fissures.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(14, 20), (24, 28), (28, 40), (38, 44), (50, 52)], (30, 30, 30, 150), 1.1)
    line(d, [(24, 28), (34, 24), (40, 16)], (30, 30, 30, 130), 0.8)
    decals.append(img)
    # 2 : plaque d'égout.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 32, 13, 13, (70, 70, 75, 255), (30, 30, 35, 255), 1.2)
    for k in range(-2, 3):
        line(d, [(32 - 9 + abs(k) * 1.5, 32 + k * 4), (32 + 9 - abs(k) * 1.5, 32 + k * 4)], (45, 45, 50, 255), 1.2)
    decals.append(img)
    # 3 : flaque.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 34, 14, 8, (60, 80, 110, 120))
    ellipse(d, 42, 30, 6, 4, (60, 80, 110, 110))
    ellipse(d, 28, 32, 6, 2, (200, 220, 240, 90))
    decals.append(img)
    # 4 : feuilles mortes.
    img = layer(); d = ImageDraw.Draw(img)
    rng = random.Random(4)
    for _ in range(7):
        cx, cy, a = rng.uniform(18, 46), rng.uniform(18, 46), rng.uniform(0, math.pi)
        color = rng.choice([(200, 120, 40, 255), (170, 70, 30, 255), (210, 170, 60, 255)])
        points = [(cx + 4 * math.cos(a), cy + 4 * math.sin(a)), (cx + 1.6 * math.cos(a + 1.6), cy + 1.6 * math.sin(a + 1.6)),
                  (cx - 4 * math.cos(a), cy - 4 * math.sin(a)), (cx + 1.6 * math.cos(a - 1.6), cy + 1.6 * math.sin(a - 1.6))]
        polygon(d, points, color)
    decals.append(soft_shadow(img, blur=0.8, alpha=0.3))
    # 5 : papiers.
    img = layer(); d = ImageDraw.Draw(img)
    polygon(d, [(20, 26), (32, 22), (35, 31), (23, 35)], (235, 232, 220, 255), (150, 150, 140, 255), 0.5)
    polygon(d, [(36, 38), (45, 36), (46, 43), (37, 45)], (230, 225, 200, 255), (150, 150, 140, 255), 0.5)
    line(d, [(23, 28), (31, 25)], (150, 150, 160, 255), 0.6)
    decals.append(soft_shadow(img, blur=0.8, alpha=0.3))
    # 6 : grille d'évacuation.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 22, 26, 42, 38, (50, 50, 55, 255), (25, 25, 30, 255), 1.0, 1)
    for k in range(5):
        line(d, [(25 + k * 3.6, 28), (25 + k * 3.6, 36)], (110, 110, 115, 255), 1.1)
    decals.append(img)
    # 7 : fleurs entre les dalles.
    img = layer(); d = ImageDraw.Draw(img)
    rng = random.Random(11)
    for _ in range(6):
        cx, cy = rng.uniform(20, 44), rng.uniform(20, 44)
        line(d, [(cx, cy), (cx + rng.uniform(-1, 1), cy + 5)], (70, 130, 60, 255), 0.8)
        color = rng.choice([(240, 220, 80, 255), (240, 120, 150, 255), (250, 250, 250, 255)])
        for k in range(5):
            a = k * math.tau / 5
            ellipse(d, cx + 1.5 * math.cos(a), cy + 1.5 * math.sin(a), 1.2, 1.2, color)
        ellipse(d, cx, cy, 0.8, 0.8, (230, 150, 40, 255))
    decals.append(img)
    return decals


def necropolis_decals():
    decals = []
    bone = (225, 218, 195, 255)
    # 0 : os croisés.
    img = layer(); d = ImageDraw.Draw(img)
    for a, b in (((20, 24), (44, 42)), ((22, 42), (42, 24))):
        line(d, [a, b], bone, 2.4)
        for x, y in (a, b):
            ellipse(d, x - 1.5, y, 2, 2, bone)
            ellipse(d, x + 1.5, y, 2, 2, bone)
    decals.append(soft_shadow(img, blur=1.0, alpha=0.35))
    # 1 : crâne.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 30, 8, 7, bone, (120, 112, 95, 255), 0.8)
    rect(d, 28, 34, 36, 39, bone, (120, 112, 95, 255), 0.6, 1)
    ellipse(d, 29, 30, 2.2, 2.4, (40, 35, 30, 255))
    ellipse(d, 35, 30, 2.2, 2.4, (40, 35, 30, 255))
    decals.append(soft_shadow(img, blur=1.0, alpha=0.35))
    # 2 : bougies.
    img = layer(); d = ImageDraw.Draw(img)
    for x, h in ((26, 9), (33, 13), (39, 7)):
        rect(d, x - 2, 42 - h, x + 2, 42, (235, 228, 205, 255), (150, 140, 120, 255), 0.5, 1)
        ellipse(d, x, 40 - h, 2.6, 3.2, (255, 200, 80, 140))
        ellipse(d, x, 40 - h, 1.1, 1.8, (255, 240, 170, 255))
    decals.append(soft_shadow(img, blur=0.8, alpha=0.3))
    # 3 : herbes mortes.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy in ((24, 38), (38, 32), (34, 44)):
        for k in range(6):
            a = -math.pi / 2 + (k - 2.5) * 0.32
            line(d, [(cx, cy), (cx + 7 * math.cos(a), cy + 8 * math.sin(a))], (140, 125, 80, 255), 1.0)
    decals.append(soft_shadow(img, blur=1.0, alpha=0.25))
    # 4 : toile d'araignée.
    img = layer(); d = ImageDraw.Draw(img)
    for k in range(8):
        a = k * math.tau / 8
        line(d, [(32, 32), (32 + 16 * math.cos(a), 32 + 16 * math.sin(a))], (230, 230, 235, 110), 0.5)
    for r in (5, 9, 13):
        points = [(32 + r * math.cos(k * math.tau / 8), 32 + r * math.sin(k * math.tau / 8)) for k in range(9)]
        line(d, points, (230, 230, 235, 110), 0.5)
    decals.append(img)
    # 5 : champignons pâles.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((26, 36, 4.5), (34, 32, 5.5), (40, 40, 3.5)):
        rect(d, cx - 1, cy, cx + 1, cy + 5, (220, 215, 200, 255))
        ellipse(d, cx, cy, r, r * 0.6, (170, 160, 200, 255), (90, 80, 120, 255), 0.6)
    decals.append(soft_shadow(img, blur=0.8, alpha=0.3))
    # 6 : brume verdâtre.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, rx in ((28, 34, 14), (38, 30, 10), (32, 28, 8)):
        ellipse(d, cx, cy, rx, rx * 0.5, (120, 200, 140, 45))
    decals.append(img.filter(ImageFilter.GaussianBlur(s(1.5))))
    # 7 : terre retournée d'une tombe fraîche.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 22, 18, 42, 48, (85, 65, 50, 255), (55, 40, 30, 255), 0.8, 6)
    for k in range(5):
        ellipse(d, 26 + k * 3.5, 24 + (k % 2) * 14, 2.4, 1.6, (110, 88, 66, 255))
    decals.append(soft_shadow(img, blur=1.0, alpha=0.3))
    return decals


# --- Obstacles (gris, teintés en jeu) et détails du chemin ---------------------

def shade(v, a=255):
    return (v, v, v, a)


def rock(d, rng):
    points = []
    for k in range(9):
        a = k * math.tau / 9
        r = rng.uniform(17, 23)
        points.append((32 + r * math.cos(a), 34 + r * 0.8 * math.sin(a)))
    polygon(d, points, shade(190), shade(90), 1.2)
    polygon(d, [(p[0] * 0.6 + 12.8, p[1] * 0.6 + 11) for p in points[4:8]], shade(225))


def hive_obstacles():
    obstacles = []
    # 0 : dôme de ruche percé de trous.
    img = layer(); d = ImageDraw.Draw(img)
    ellipse(d, 32, 36, 24, 20, shade(170), shade(80), 1.2)
    ellipse(d, 32, 30, 18, 13, shade(205))
    for cx, cy, r in ((26, 30, 3.2), (38, 28, 2.6), (32, 39, 3.6), (42, 38, 2.4), (21, 40, 2.2)):
        ellipse(d, cx, cy, r, r * 0.8, shade(55))
    obstacles.append(soft_shadow(img))
    # 1 : sac d'œufs géant.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy, r in ((24, 38, 11), (40, 38, 10), (32, 25, 12)):
        ellipse(d, cx, cy, r, r * 1.1, shade(215), shade(95), 1.2)
        ellipse(d, cx - r * 0.35, cy - r * 0.4, r * 0.3, r * 0.3, shade(250))
    obstacles.append(soft_shadow(img))
    # 2 : épines de chitine.
    img = layer(); d = ImageDraw.Draw(img)
    for x, h, w in ((20, 30, 7), (44, 26, 6), (32, 44, 9)):
        polygon(d, [(x - w, 54), (x, 54 - h), (x + w, 54)], shade(170), shade(70), 1.0)
        polygon(d, [(x - w * 0.3, 54), (x, 54 - h), (x + w * 0.1, 54)], shade(215))
    obstacles.append(soft_shadow(img))
    # 3 : rocher.
    img = layer(); d = ImageDraw.Draw(img)
    rock(d, random.Random(3))
    obstacles.append(soft_shadow(img))
    return obstacles


def foundry_obstacles():
    obstacles = []
    # 0 : caisse.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 12, 12, 52, 52, shade(185), shade(70), 1.4, 2)
    rect(d, 16, 16, 48, 48, None, shade(120), 1.0, 1)
    line(d, [(17, 17), (47, 47)], shade(120), 2.4)
    line(d, [(47, 17), (17, 47)], shade(120), 2.4)
    obstacles.append(soft_shadow(img))
    # 1 : barils.
    img = layer(); d = ImageDraw.Draw(img)
    for cx, cy in ((23, 26), (41, 28), (31, 42)):
        ellipse(d, cx, cy, 10, 10, shade(165), shade(70), 1.2)
        ellipse(d, cx, cy, 6.5, 6.5, None, shade(110), 0.9)
        ellipse(d, cx - 3, cy - 3, 2, 2, shade(225))
    obstacles.append(soft_shadow(img))
    # 2 : machine et tuyau.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 10, 20, 44, 50, shade(170), shade(70), 1.4, 3)
    rect(d, 15, 25, 30, 35, shade(90), None, 0, 1)
    for k in range(3):
        ellipse(d, 37, 27 + k * 7, 2, 2, shade(225))
    line(d, [(44, 30), (54, 30), (54, 12)], shade(70), 6)
    line(d, [(44, 30), (54, 30), (54, 12)], shade(175), 3.6)
    obstacles.append(soft_shadow(img))
    # 3 : tas de ferraille.
    img = layer(); d = ImageDraw.Draw(img)
    polygon(d, [(10, 50), (20, 30), (30, 36), (38, 22), (52, 34), (56, 50)], shade(150), shade(70), 1.2)
    rect(d, 18, 36, 34, 44, shade(200), shade(80), 0.8)
    line(d, [(36, 30), (50, 44)], shade(215), 2.2)
    ellipse(d, 44, 46, 4, 4, shade(110), shade(60), 0.8)
    obstacles.append(soft_shadow(img))
    return obstacles


def city_obstacles():
    obstacles = []
    # 0 : pan de mur en briques.
    img = layer(); d = ImageDraw.Draw(img)
    polygon(d, [(10, 52), (10, 22), (22, 16), (30, 24), (40, 12), (54, 20), (54, 52)], shade(175), shade(70), 1.2)
    for row in range(5):
        y = 46 - row * 7
        for k in range(4):
            x = 12 + k * 11 + (row % 2) * 5
            if x + 9 <= 53:
                line(d, [(x, y), (x + 9, y)], shade(110), 0.8)
    obstacles.append(soft_shadow(img))
    # 1 : arbre en bac.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 20, 36, 44, 54, shade(160), shade(70), 1.2, 2)
    for cx, cy, r in ((26, 28, 11), (38, 26, 11), (32, 18, 11), (32, 30, 12)):
        ellipse(d, cx, cy, r, r, shade(140), shade(70), 1.0)
    for cx, cy, r in ((28, 22, 4), (36, 20, 3)):
        ellipse(d, cx, cy, r, r, shade(200))
    obstacles.append(soft_shadow(img))
    # 2 : barricade.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(14, 52), (24, 28)], shade(90), 3)
    line(d, [(50, 52), (40, 28)], shade(90), 3)
    rect(d, 8, 26, 56, 36, shade(220), shade(70), 1.2, 1.5)
    for k in range(4):
        x = 12 + k * 12
        polygon(d, [(x, 35), (x + 5, 27), (x + 9, 27), (x + 4, 35)], shade(80))
    obstacles.append(soft_shadow(img))
    # 3 : gravats.
    img = layer(); d = ImageDraw.Draw(img)
    rng = random.Random(9)
    for cx, cy, r in ((24, 40, 10), (40, 40, 9), (32, 28, 9), (46, 30, 6), (18, 28, 6)):
        points = [(cx + r * rng.uniform(0.7, 1.1) * math.cos(a), cy + r * rng.uniform(0.6, 0.9) * math.sin(a))
                  for a in np.linspace(0, math.tau, 6, endpoint=False) + rng.uniform(0, 1)]
        polygon(d, points, shade(rng.randint(150, 200)), shade(70), 1.0)
    obstacles.append(soft_shadow(img))
    return obstacles


def necropolis_obstacles():
    obstacles = []
    # 0 : pierre tombale arrondie.
    img = layer(); d = ImageDraw.Draw(img)
    polygon(d, [(18, 54), (18, 24), (22, 15), (32, 11), (42, 15), (46, 24), (46, 54)], shade(185), shade(70), 1.4)
    line(d, [(32, 20), (32, 36)], shade(105), 2.2)
    line(d, [(26, 25), (38, 25)], shade(105), 2.2)
    line(d, [(22, 44), (42, 44)], shade(130), 1.0)
    obstacles.append(soft_shadow(img))
    # 1 : croix de pierre penchée.
    img = layer(); d = ImageDraw.Draw(img)
    polygon(d, [(28, 56), (25, 14), (33, 13), (36, 56)], shade(175), shade(70), 1.2)
    polygon(d, [(15, 25), (44, 22), (45, 30), (16, 33)], shade(175), shade(70), 1.2)
    ellipse(d, 32, 56, 14, 4, shade(120))
    obstacles.append(soft_shadow(img))
    # 2 : colonne brisée.
    img = layer(); d = ImageDraw.Draw(img)
    rect(d, 14, 44, 50, 54, shade(160), shade(70), 1.2, 1)
    rect(d, 20, 18, 44, 46, shade(190), shade(70), 1.2)
    for x in (25, 32, 39):
        line(d, [(x, 20), (x, 44)], shade(140), 1.0)
    polygon(d, [(20, 18), (26, 12), (31, 17), (37, 10), (44, 18)], shade(190), shade(70), 1.2)
    obstacles.append(soft_shadow(img))
    # 3 : arbre mort.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(32, 56), (31, 38), (34, 26)], shade(110), 5)
    for branch in ([(31, 38), (20, 30), (14, 20)], [(34, 26), (44, 16), (50, 14)], [(33, 32), (44, 30)],
                   [(20, 30), (22, 18)], [(34, 26), (30, 12)]):
        line(d, branch, shade(110), 2.4)
    obstacles.append(soft_shadow(img))
    return obstacles


def path_details(seed):
    """Petits détails transparents semés sur le chemin : cailloux, fissure, taches."""
    rng = random.Random(seed)
    details = []
    # Cailloux.
    for _ in range(2):
        img = layer(); d = ImageDraw.Draw(img)
        for _ in range(rng.randint(3, 5)):
            cx, cy, r = rng.uniform(22, 42), rng.uniform(22, 42), rng.uniform(1.4, 3)
            ellipse(d, cx, cy + 0.8, r, r * 0.8, (0, 0, 0, 70))
            ellipse(d, cx, cy, r, r * 0.8, (255, 255, 255, 70))
        details.append(img)
    # Fissure.
    img = layer(); d = ImageDraw.Draw(img)
    line(d, [(20, 26), (28, 31), (32, 38), (42, 40)], (0, 0, 0, 80), 1.0)
    details.append(img)
    # Tache sombre.
    img = layer(); d = ImageDraw.Draw(img)
    for r, a in ((9, 30), (5, 35)):
        ellipse(d, 32, 32, r, r * 0.7, (0, 0, 0, a))
    details.append(img)
    return details


BIOMES = {
    "insectoid": (hive_grounds, hive_decals, hive_obstacles, 1),
    "mecha": (foundry_grounds, foundry_decals, foundry_obstacles, 2),
    "humanoid": (city_grounds, city_decals, city_obstacles, 3),
    "undead": (necropolis_grounds, necropolis_decals, necropolis_obstacles, 4),
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    names = sys.argv[1:] or list(BIOMES)
    for name in names:
        grounds, decals, obstacles, seed = BIOMES[name]
        rng = np.random.default_rng(seed)
        sheet = Image.new("RGBA", (TILE * COLUMNS, TILE * ROWS), (0, 0, 0, 0))
        rows = [grounds(rng), decals(), obstacles() + path_details(seed)]
        for row, tiles in enumerate(rows):
            assert len(tiles) == COLUMNS, (name, row, len(tiles))
            for column, tile in enumerate(tiles):
                sheet.alpha_composite(shrink(tile), (column * TILE, row * TILE))
        path = os.path.join(OUT_DIR, name + ".png")
        sheet.save(path, optimize=True)
        print(path)


if __name__ == "__main__":
    main()
