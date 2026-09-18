#!/usr/bin/env python3
"""Malla de terreno (.glb) desde una rejilla de alturas combinada.

Entrada: dict JSON de setup_terrain.py (origin, tile_size, n_tiles, grid
de alturas en metros ya rebasadas). Salida: .glb con posiciones, normales
(diferencias finitas), UV planares y un material de hierba.

Uso:
    python3 lnd_to_glb.py --grid terreno.json --output terreno.glb
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys


class GlbWriter:
    def __init__(self):
        self.bin = bytearray()
        self.views = []
        self.accessors = []

    def add_view(self, data: bytes) -> int:
        off = len(self.bin)
        self.bin += data
        self.bin += b"\x00" * (-len(self.bin) % 4)
        idx = len(self.views)
        self.views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data)})
        return idx

    def add_accessor(self, view: int, comp: int, count: int, atype: str,
                     minimum=None, maximum=None) -> int:
        idx = len(self.accessors)
        acc: dict = {"bufferView": view, "componentType": comp,
                     "count": count, "type": atype}
        if minimum is not None:
            acc["min"] = minimum
            acc["max"] = maximum
        self.accessors.append(acc)
        return idx


def build(spec: dict) -> bytes:
    n = int(spec["n"])  # verts por lado de la malla combinada
    step = float(spec["tile_size"]) / 128.0
    ox, oz = spec["origin"]
    hs = spec["heights"]
    assert len(hs) == n * n, f"rejilla {len(hs)} != {n}x{n}"

    def h(ix: int, iz: int) -> float:
        ix = min(max(ix, 0), n - 1)
        iz = min(max(iz, 0), n - 1)
        return hs[iz * n + ix]

    pos, nor, uv = [], [], []
    for iz in range(n):
        for ix in range(n):
            x = ox + ix * step
            z = oz + iz * step
            pos += [x, h(ix, iz), z]
            dx = (h(ix + 1, iz) - h(ix - 1, iz)) / (2.0 * step)
            dz = (h(ix, iz + 1) - h(ix, iz - 1)) / (2.0 * step)
            inv = 1.0 / math.sqrt(dx * dx + 1.0 + dz * dz)
            nor += [-dx * inv, inv, -dz * inv]
            uv += [ix / (n - 1), iz / (n - 1)]

    idx = []
    for iz in range(n - 1):
        for ix in range(n - 1):
            a = iz * n + ix
            b = a + 1
            c = a + n
            e = c + 1
            idx += [a, c, b, b, c, e]

    w = GlbWriter()
    pbin = struct.pack(f"<{len(pos)}f", *pos)
    nbin = struct.pack(f"<{len(nor)}f", *nor)
    ubin = struct.pack(f"<{len(uv)}f", *uv)
    ibin = struct.pack(f"<{len(idx)}I", *idx)
    pa = w.add_accessor(w.add_view(pbin), 5126, n * n, "VEC3",
                        [min(pos[0::3]), min(pos[1::3]), min(pos[2::3])],
                        [max(pos[0::3]), max(pos[1::3]), max(pos[2::3])])
    na = w.add_accessor(w.add_view(nbin), 5126, n * n, "VEC3")
    ta = w.add_accessor(w.add_view(ubin), 5126, n * n, "VEC2")
    ia = w.add_accessor(w.add_view(ibin), 5125, len(idx), "SCALAR")
    gltf = {
        "asset": {"version": "2.0", "generator": "aethermere lnd_to_glb"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "terrain", "mesh": 0}],
        "meshes": [{"name": "terrain", "primitives": [{"attributes": {
            "POSITION": pa, "NORMAL": na, "TEXCOORD_0": ta},
            "indices": ia, "material": 0, "mode": 4}]}],
        "materials": [{"name": "grass",
                       "pbrMetallicRoughness": {
                           "baseColorFactor": [0.32, 0.38, 0.3, 1.0],
                           "metallicFactor": 0.0, "roughnessFactor": 1.0}}],
        "accessors": w.accessors,
        "bufferViews": w.views,
        "buffers": [{"byteLength": len(w.bin)}],
    }

    def pad(data: bytes, char: bytes) -> bytes:
        return data + char * (-len(data) % 4)

    j = pad(json.dumps(gltf, separators=(",", ":")).encode(), b" ")
    b = pad(bytes(w.bin), b"\x00")
    total = 12 + 8 + len(j) + 8 + len(b)
    out = struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(j), 0x4E4F534A) + j
    out += struct.pack("<II", len(b), 0x004E4942) + b
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Rejilla de alturas a .glb")
    ap.add_argument("--grid", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args(argv)
    with open(args.grid, encoding="utf-8") as f:
        spec = json.load(f)
    glb = build(spec)
    with open(args.output, "wb") as f:
        f.write(glb)
    print(f"OK rejilla {spec['n']}x{spec['n']} -> {args.output} ({len(glb)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
