#!/usr/bin/env python3
"""Prepara el terreno de Ironhold desde el cliente FlyFF.

Lee tiles .lnd, cose un bloque (defecto 2x2: x10-11/y16-17, costa suave),
aplana el vacio a nivel del mar, rebasa (mar -> y=0) y centra el tile
(10,17) en el origen del juego. Genera:
  - terrain_ironhold.glb  (visual con textura del atlas, via lnd_to_glb.py)
  - terrain_ironhold.json (rejilla para colision HeightMap + snap en Godot,
    mas puestos de hierba/arboles)
  - terrain_ironhold_atlas.png (2x2 texturas .dds del cliente via .res)

Como audio/texturas/modelos, no se versiona (ver .gitignore).
Requiere pillow para el atlas (sin el: verde plano + sin hierba).

Uso:
    python3 setup_terrain.py --client /ruta/a/app --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)
sys.path.insert(0, os.path.join(_HERE, "..", "parsers"))
from lnd_parser import parse_lnd, GRID  # noqa: E402
from lnd_to_glb import build as build_glb  # noqa: E402
from res_parser import extract_res  # noqa: E402

TILES = [(10, 16), (11, 16), (10, 17), (11, 17)]
CENTER_TILE = (10, 17)  # su centro queda en el origen del juego
TILE_SIZE = 128.0
SEA_H = 100.0
VOID_OVER = 2000.0
TILE_PX = 256  # las .dds del cliente son 256x256
# Lamina de agua: la cubeta queda bajo la cota del oceano oeste (el
# spawn pisa -12.5); -14 deja el campamento seco y encharca las hoyas.
WATER_Y = -14.0

# Hierba/árboles: semilla fija, sobre el mar; la hierba aguanta ladera
# (la costa es escarpada y el verde pintado manda).
VEG_SEED = 7
VEG_STEP = 1.0
VEG_MIN_H = 0.3
VEG_GRASS_SLOPE = 2.5
VEG_TREE_SLOPE = 2.0
VEG_MAX_GRASS = 900
VEG_MAX_TREES = 60


def tile_textures(client_dir: str, tiles: list[tuple[int, int]],
                  work_dir: str) -> dict[tuple[int, int], str]:
    """Extrae los .dds de los tiles desde sus packs .res y los pasa a PNG.

    Los packs `WdMadrigal_XX-YY.res` agrupan 5x5 texturas desde multiplos
    de 5. Devuelve tile -> ruta PNG (falta la entrada si PIL no puede).
    """
    from PIL import Image  # type: ignore

    os.makedirs(work_dir, exist_ok=True)
    by_pack: dict[tuple[int, int], list[tuple[int, int]]] = {}
    for t in tiles:
        by_pack.setdefault((t[0] // 5 * 5, t[1] // 5 * 5), []).append(t)
    out: dict[tuple[int, int], str] = {}
    for (px, py), ts in by_pack.items():
        pack = os.path.join(client_dir, "World", "WdMadrigal",
                            f"WdMadrigal_{px:02d}-{py:02d}.res")
        if not os.path.isfile(pack):
            print(f"sin pack de texturas {px}-{py}: {pack}")
            continue
        want = {f"WdMadrigal{tx:02d}-{ty:02d}.dds" for tx, ty in ts}
        got = extract_res(pack, work_dir, want)
        for name in got:
            tx, ty = int(name[10:12]), int(name[13:15])
            png = os.path.join(work_dir, name.replace(".dds", ".png"))
            try:
                Image.open(os.path.join(work_dir, name)).save(png)
            except OSError as e:
                print(f"DDS ilegible {name}: {e}")
                continue
            out[(tx, ty)] = png
    return out


def is_veg(px: tuple[int, int, int]) -> bool:
    r, g, b = px
    return g > r + 25 and g > b + 15


def is_tree(px: tuple[int, int, int]) -> bool:
    r, g, b = px
    return g > 110 and r < 110 and b < 140


def veg_spots(tile_pngs: dict[tuple[int, int], str], xs: list[int],
              ys: list[int], heights: list[float], n: int, step: float,
              ox: float, oz: float) -> tuple[list, list]:
    """Puestos de hierba/arboles sobre verde pintado (determinista)."""
    from PIL import Image  # type: ignore
    import random

    imgs = {}
    for t, p in tile_pngs.items():
        imgs[t] = Image.open(p).convert("RGB").load()
    if len(imgs) != len(xs) * len(ys):
        return [], []

    def px_at(t, lx, lz):
        return imgs[t][min(max(lx, 0), TILE_PX - 1),
                       min(max(lz, 0), TILE_PX - 1)]

    def green_near(t, lx, lz) -> tuple[bool, bool]:
        veg = tree = False
        for dz in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                p = px_at(t, lx + dx, lz + dz)
                if is_tree(p):
                    return True, True
                if is_veg(p):
                    veg = True
        return veg, tree

    def h_at(ix: int, iz: int) -> float:
        ix = min(max(ix, 0), n - 1)
        iz = min(max(iz, 0), n - 1)
        return heights[iz * n + ix]

    def slope(ix: int, iz: int) -> float:
        dx = (h_at(ix + 1, iz) - h_at(ix - 1, iz)) / (2.0 * step)
        dz = (h_at(ix, iz + 1) - h_at(ix, iz - 1)) / (2.0 * step)
        return abs(dx) + abs(dz)

    rnd = random.Random(VEG_SEED)
    grass, trees = [], []
    x0, z0 = ox, oz
    x1, z1 = ox + (n - 1) * step, oz + (n - 1) * step
    x = x0 + 1.0
    while x < x1 - 1.0 and (len(grass) < VEG_MAX_GRASS
                            or len(trees) < VEG_MAX_TREES):
        z = z0 + 1.0
        while z < z1 - 1.0 and (len(grass) < VEG_MAX_GRASS
                                or len(trees) < VEG_MAX_TREES):
            jx = x + rnd.uniform(-0.8, 0.8)
            jz = z + rnd.uniform(-0.8, 0.8)
            fx = (jx - x0) / step
            fz = (jz - z0) / step
            ix, iz = int(fx), int(fz)
            tix = min(ix // (GRID - 1), len(xs) - 1)
            tiz = min(iz // (GRID - 1), len(ys) - 1)
            t = (xs[tix], ys[tiz])
            lx = min(max(int((fx - tix * (GRID - 1)) / (GRID - 1) * TILE_PX),
                         0), TILE_PX - 1)
            lz = min(max(int((fz - tiz * (GRID - 1)) / (GRID - 1) * TILE_PX),
                         0), TILE_PX - 1)
            s = slope(ix, iz)
            if h_at(ix, iz) <= VEG_MIN_H:
                pass
            else:
                veg, tree = green_near(t, lx, lz)
                if tree and s < VEG_TREE_SLOPE \
                        and len(trees) < VEG_MAX_TREES:
                    trees.append([round(jx, 2), round(jz, 2),
                                  round(rnd.uniform(0.8, 1.3), 2)])
                elif veg and s < VEG_GRASS_SLOPE \
                        and len(grass) < VEG_MAX_GRASS:
                    grass.append([round(jx, 2), round(jz, 2),
                                  round(rnd.uniform(0.7, 1.4), 2)])
            z += VEG_STEP
        x += VEG_STEP
    return grass, trees
def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara terreno de Ironhold")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    ap.add_argument("--tile-size", type=float, default=TILE_SIZE)
    ap.add_argument("--sea", type=float, default=SEA_H)
    args = ap.parse_args(argv)

    grids = {}
    for tx, ty in TILES:
        p = os.path.join(args.client, "World", "WdMadrigal",
                         f"WdMadrigal{tx:02d}-{ty:02d}.lnd")
        if not os.path.isfile(p):
            print(f"falta tile {tx}-{ty}: {p}", file=sys.stderr)
            return 1
        r = parse_lnd(p)
        grids[(tx, ty)] = list(r["heights"])
        print(f"OK tile {tx}-{ty} (vacio {r['stats']['void_frac']:.3f})")

    xs = sorted({t[0] for t in TILES})
    ys = sorted({t[1] for t in TILES})
    nx, ny = len(xs), len(ys)
    n = nx * (GRID - 1) + 1
    assert n == ny * (GRID - 1) + 1
    raw = [0.0] * (n * n)
    mask = [False] * (n * n)  # True = vacio (>2000), a rellenar
    for j, ty in enumerate(ys):
        for i, tx in enumerate(xs):
            g = grids[(tx, ty)]
            for lz in range(GRID):
                for lx in range(GRID):
                    v = g[lz * GRID + lx]
                    k = (j * (GRID - 1) + lz) * n + i * (GRID - 1) + lx
                    raw[k] = v
                    mask[k] = v > VOID_OVER
    # Difusion desde vecinos conocidos: sin muros de 100 m, relieve continuo.
    filled = list(raw)
    frontier = [k for k in range(n * n) if mask[k]]
    for _ in range(10000):
        if not frontier:
            break
        nxt = []
        for k in frontier:
            ix, iz = k % n, k // n
            acc, cnt = 0.0, 0
            for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                jx, jz = ix + dx, iz + dz
                if 0 <= jx < n and 0 <= jz < n and not mask[jz * n + jx]:
                    acc += filled[jz * n + jx]
                    cnt += 1
            if cnt:
                filled[k] = acc / cnt
                mask[k] = False
            else:
                nxt.append(k)
        frontier = nxt
    for k in frontier:  # reducto sin vecinos conocidos: nivel del mar
        filled[k] = args.sea
        mask[k] = False
    stitched = [v - args.sea for v in filled]
    # Origen: centro de CENTER_TILE en (0, 0) del juego.
    step = args.tile_size / (GRID - 1)
    ci = xs.index(CENTER_TILE[0])
    cj = ys.index(CENTER_TILE[1])
    ox = -(ci * (GRID - 1) + (GRID - 1) / 2) * step
    oz = -(cj * (GRID - 1) + (GRID - 1) / 2) * step
    spec = {
        "n": n,
        "tile_size": args.tile_size,
        "origin": [ox, oz],
        "tiles": [list(t) for t in TILES],
        "sea": args.sea,
        "water_y": WATER_Y,
        "heights": stitched,
    }
    os.makedirs(args.out, exist_ok=True)
    # Atlas de texturas + puestos de vegetacion (requiere PIL; si falla,
    # el juego repliega al verde plano).
    atlas_png = None
    try:
        import tempfile
        from PIL import Image  # type: ignore

        with tempfile.TemporaryDirectory(prefix="wdtex_") as tmp:
            tile_pngs = tile_textures(args.client, TILES, tmp)
            if len(tile_pngs) == len(TILES):
                atlas = Image.new("RGB", (len(xs) * TILE_PX,
                                          len(ys) * TILE_PX))
                for (tx, ty), p in tile_pngs.items():
                    atlas.paste(Image.open(p).convert("RGB"),
                                ((xs.index(tx)) * TILE_PX,
                                 (ys.index(ty)) * TILE_PX))
                ap_path = os.path.join(args.out,
                                       "terrain_ironhold_atlas.png")
                atlas.save(ap_path)
                with open(ap_path, "rb") as f:
                    atlas_png = f.read()
                print(f"atlas {atlas.size[0]}x{atlas.size[1]} -> {ap_path}")
                grass, trees = veg_spots(tile_pngs, xs, ys, stitched,
                                         n, step, ox, oz)
                spec["grass"] = grass
                spec["trees"] = trees
                print(f"vegetacion: {len(grass)} hierbas, "
                      f"{len(trees)} arboles")
            else:
                print("sin texturas completas: verde plano + sin hierba")
    except ImportError:
        print("sin PIL: verde plano + sin hierba (pip install pillow)")
    jp = os.path.join(args.out, "terrain_ironhold.json")
    with open(jp, "w", encoding="utf-8") as f:
        json.dump(spec, f)
    if atlas_png is not None:
        spec["atlas_png"] = atlas_png
    gp = os.path.join(args.out, "terrain_ironhold.glb")
    with open(gp, "wb") as f:
        f.write(build_glb(spec))
    hs_min = min(stitched)
    hs_max = max(stitched)
    print(f"terreno {n}x{n} ({n * n} verts), cotas {hs_min:.1f}..{hs_max:.1f} m, "
          f"origen ({ox:.0f}, {oz:.0f}) -> {gp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
