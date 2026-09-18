#!/usr/bin/env python3
"""Malla de terreno (.glb) desde una rejilla de alturas combinada.

Entrada: dict JSON de setup_terrain.py (origin, tile_size, n_tiles, grid
de alturas en metros ya rebasadas, tiles para UV por cuadrante y
opcionalmente atlas_png con la textura). Salida: .glb con posiciones,
normales (diferencias finitas), UV al cuadrante del tile y material con
la textura del atlas (o hierba plana sin atlas).

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
    tiles = [tuple(t) for t in spec.get("tiles", [])]
    xs = sorted({t[0] for t in tiles})
    ys = sorted({t[1] for t in tiles})
    nx, ny = max(len(xs), 1), max(len(ys), 1)
    # Inset de medio texel del cuadrante contra el sangrado.
    inset = 0.5 / 256.0

    def uv_of(ix: int, iz: int) -> tuple[float, float]:
        if not tiles:
            return (ix / (n - 1), iz / (n - 1))
        tix = min(ix // 128, nx - 1)
        tiz = min(iz // 128, ny - 1)
        u = min(max((ix - tix * 128) / 128.0, inset), 1.0 - inset)
        v = min(max((iz - tiz * 128) / 128.0, inset), 1.0 - inset)
        return ((tix + u) / nx, (tiz + v) / ny)

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
            uv += list(uv_of(ix, iz))

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
    atlas = spec.get("atlas_png")
    if atlas is not None and isinstance(atlas, str):
        import base64
        atlas = base64.b64decode(atlas)
    if atlas is not None:
        img_view = w.add_view(bytes(atlas))
        material = {"name": "terrain",
                    "pbrMetallicRoughness": {
                        "baseColorTexture": {"index": 0},
                        "baseColorFactor": [0.82, 0.82, 0.82, 1.0],
                        "metallicFactor": 0.0, "roughnessFactor": 1.0}}
        images = [{"bufferView": img_view, "mimeType": "image/png"}]
        samplers = [{"magFilter": 9729, "minFilter": 9987,
                     "wrapS": 10497, "wrapT": 10497}]
        textures = [{"source": 0, "sampler": 0}]
    else:
        material = {"name": "grass",
                    "pbrMetallicRoughness": {
                        "baseColorFactor": [0.32, 0.38, 0.3, 1.0],
                        "metallicFactor": 0.0, "roughnessFactor": 1.0}}
        images, samplers, textures = [], [], []
    gltf = {
        "asset": {"version": "2.0", "generator": "aethermere lnd_to_glb"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "terrain", "mesh": 0}],
        "meshes": [{"name": "terrain", "primitives": [{"attributes": {
            "POSITION": pa, "NORMAL": na, "TEXCOORD_0": ta},
            "indices": ia, "material": 0, "mode": 4}]}],
        "materials": [material],
        "animations": [],
        "accessors": w.accessors,
        "bufferViews": w.views,
        "buffers": [{"byteLength": len(w.bin)}],
    }
    if images:
        gltf["images"] = images
        gltf["samplers"] = samplers
        gltf["textures"] = textures

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
