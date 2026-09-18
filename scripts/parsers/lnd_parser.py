#!/usr/bin/env python3
"""Parser del formato .lnd de FlyFF v21 (terreno por tiles).

Formato resuelto (ver docs/lnd-research.md):
  - u32 version (= 3) + u32 tile_x + u32 tile_y (coinciden con XX-YY).
  - Rejilla de alturas 129x129 f32 LE en el byte 12 (66564 B).
    3000.0 = vacio/fuera del mapa; ~100.0 = nivel del mar; tierra ~20-1500.
  - Cola variable por tile (capas/objetos, sin parsear: se registra tamano).

Uso:
    python3 lnd_parser.py --lnd WdMadrigal14-07.lnd --json salida.json
    python3 lnd_parser.py --batch /ruta/a/WdMadrigal --report
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

GRID = 129
GRID_FLOATS = GRID * GRID
HEADER_LEN = 12
HEIGHTS_LEN = GRID_FLOATS * 4

VOID_H = 3000.0
SEA_H = 100.0


def parse_lnd(path: str, heights: bool = True) -> dict:
    """Lee cabecera + rejilla de alturas. Lanza ValueError si no cuadra."""
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < HEADER_LEN + HEIGHTS_LEN:
        raise ValueError(f"muy corto ({len(data)} B)")
    version = struct.unpack_from("<I", data, 0)[0]
    tile_x, tile_y = struct.unpack_from("<II", data, 4)
    if version != 3:
        raise ValueError(f"version inesperada: {version}")
    base = os.path.basename(path)
    try:
        want = base.replace(".lnd", "").split("Madrigal")[1]
        wx, wy = (int(v) for v in want.split("-"))
        if (tile_x, tile_y) != (wx, wy):
            raise ValueError(f"coords {tile_x}-{tile_y} != nombre {want}")
    except (IndexError, ValueError) as e:
        if "coords" in str(e):
            raise
    out: dict = {
        "file": base,
        "size": len(data),
        "version": version,
        "tile": [tile_x, tile_y],
        "grid": GRID,
        "tail_size": len(data) - HEADER_LEN - HEIGHTS_LEN,
    }
    if heights:
        hs = struct.unpack_from(f"<{GRID_FLOATS}f", data, HEADER_LEN)
        out["heights"] = list(hs)
        finite = [h for h in hs if h == h and abs(h) < 1e5]
        out["stats"] = {
            "min": min(finite),
            "max": max(finite),
            "void_frac": sum(1 for h in finite if h > 2000.0) / len(finite),
            "sea_frac": sum(1 for h in finite if h == SEA_H) / len(finite),
        }
    return out


def edge_continuity(a: list[float], b: list[float], edge: str) -> float:
    """Diferencia media del borde compartido ('E-W' u 'S-N')."""
    if edge == "E-W":
        pairs = [(a[r * GRID + GRID - 1], b[r * GRID]) for r in range(GRID)]
    else:
        pairs = [(a[(GRID - 1) * GRID + c], b[c]) for c in range(GRID)]
    return sum(abs(x - y) for x, y in pairs) / len(pairs)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Parser .lnd de FlyFF")
    ap.add_argument("--lnd", help="Tile a parsear")
    ap.add_argument("--json", help="Destino del JSON")
    ap.add_argument("--batch", help="Directorio con *.lnd para informe")
    args = ap.parse_args(argv)

    if args.batch:
        files = sorted(glob.glob(os.path.join(args.batch, "*.lnd")))
        if not files:
            print("sin .lnd", file=sys.stderr)
            return 1
        bad, voids = 0, 0
        for p in files:
            try:
                r = parse_lnd(p)
                if r["stats"]["void_frac"] > 0.999:
                    voids += 1
            except ValueError as e:
                bad += 1
                print(f"MAL {p}: {e}", file=sys.stderr)
        print(f"tiles: {len(files)}, mal: {bad}, vacios: {voids}")
        return 1 if bad else 0

    if not args.lnd:
        ap.error("falta --lnd o --batch")
    r = parse_lnd(args.lnd)
    text = json.dumps({k: v for k, v in r.items()}, ensure_ascii=False)
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text[:400])
    s = r["stats"]
    print(f"OK {r['file']}: {r['size']} B, rejilla {r['grid']}x{r['grid']}, "
          f"min {s['min']:.1f} max {s['max']:.1f}, vacio {s['void_frac']:.2f}, "
          f"cola {r['tail_size']} B")
    return 0


if __name__ == "__main__":
    sys.exit(main())
