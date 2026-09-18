#!/usr/bin/env python3
"""Prepara el terreno de Ironhold desde el cliente FlyFF.

Lee tiles .lnd, cose un bloque (defecto 2x2: x10-11/y16-17, costa suave),
aplana el vacio a nivel del mar, rebasa (mar -> y=0) y centra el tile
(10,17) en el origen del juego. Genera:
  - terrain_ironhold.glb  (visual, via lnd_to_glb.py)
  - terrain_ironhold.json (rejilla para colision HeightMap + snap en Godot)

Como audio/texturas/modelos, no se versiona (ver .gitignore).

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

TILES = [(10, 16), (11, 16), (10, 17), (11, 17)]
CENTER_TILE = (10, 17)  # su centro queda en el origen del juego
TILE_SIZE = 128.0
SEA_H = 100.0
VOID_OVER = 2000.0


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
        "heights": stitched,
    }
    os.makedirs(args.out, exist_ok=True)
    jp = os.path.join(args.out, "terrain_ironhold.json")
    with open(jp, "w", encoding="utf-8") as f:
        json.dump(spec, f)
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
