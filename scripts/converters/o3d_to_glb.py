#!/usr/bin/env python3
"""Convierte .o3d FlyFF a .glb (glTF 2.0 binario) sin dependencias.

Geometria por GMOBJECT: POSITION/NORMAL/TEXCOORD_0, INDICES u16 (u32 si
hace falta), JOINTS_0/WEIGHTS_0 si es SKIN. Un material por objeto con
el nombre de la textura FlyFF en ``extras`` (las .dds se convertiran en
Fase 5). La matriz local se vuelca tal cual (ver design.md).

Uso:
    python3 o3d_to_glb.py --input modelo.o3d --output modelo.glb
    python3 o3d_to_glb.py --input "Model/*.o3d" --output-dir out/
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "parsers"))
from o3d_parser import parse_o3d  # noqa: E402


def _pad(data: bytes, char: bytes) -> bytes:
    return data + char * (-len(data) % 4)


class GlbWriter:
    def __init__(self):
        self.bin = bytearray()
        self.views = []
        self.accessors = []
        self.meshes = []
        self.nodes = []
        self.materials = []
        self.mat_cache: dict[str, int] = {}

    def add_view(self, data: bytes) -> int:
        off = len(self.bin)
        self.bin += data
        # pad interno para alinear el siguiente accessor a 4
        self.bin += b"\x00" * (-len(self.bin) % 4)
        idx = len(self.views)
        self.views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data)})
        return idx

    def add_accessor(self, view: int, comp: int, count: int, atype: str,
                     minimum: list | None = None, maximum: list | None = None,
                     normalized: bool = False) -> int:
        idx = len(self.accessors)
        acc: dict = {"bufferView": view, "componentType": comp, "count": count,
                     "type": atype}
        if normalized:
            acc["normalized"] = True
        if minimum is not None:
            acc["min"] = minimum
            acc["max"] = maximum
        self.accessors.append(acc)
        return idx

    def material(self, name: str, texture: str) -> int:
        if name in self.mat_cache:
            return self.mat_cache[name]
        idx = len(self.materials)
        self.materials.append({
            "name": name,
            "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1],
                                     "metallicFactor": 0.0, "roughnessFactor": 0.9},
            "extras": {"flyff_texture": texture},
        })
        self.mat_cache[name] = idx
        return idx


def convert(parsed: dict, group: int = 0) -> bytes:
    w = GlbWriter()
    groups = parsed["groups"] if group < 0 else [parsed["groups"][group]]
    for gi, grp in enumerate(groups):
        for oi, o in enumerate(grp["objects"]):
            n = o["counts"]["vb"]
            if n == 0 or not o["indices"]:
                continue
            pos = struct.pack(f"<{len(o['positions'])}f", *o["positions"])
            nor = struct.pack(f"<{len(o['normals'])}f", *o["normals"])
            uv = struct.pack(f"<{len(o['uvs'])}f", *o["uvs"])
            idx_max = max(o["indices"])
            idx_fmt = "<H" if idx_max < 65536 else "<I"
            idx = struct.pack(f"{idx_fmt[0]}{len(o['indices'])}{idx_fmt[1]}", *o["indices"])
            ia = w.add_accessor(w.add_view(idx), 5123 if idx_fmt == "<H" else 5125,
                                len(o["indices"]), "SCALAR")
            pa = w.add_accessor(
                w.add_view(pos), 5126, n, "VEC3",
                [min(o["positions"][k::3]) for k in range(3)],
                [max(o["positions"][k::3]) for k in range(3)])
            na = w.add_accessor(w.add_view(nor), 5126, n, "VEC3")
            ta = w.add_accessor(w.add_view(uv), 5126, n, "VEC2")
            attrs = {"POSITION": pa, "NORMAL": na, "TEXCOORD_0": ta}
            if o["type"] == "SKIN":
                jn = struct.pack(f"<{len(o['joints'])}H", *[int(x) & 0xFFFF for x in o["joints"]])
                wt = struct.pack(f"<{len(o['weights'])}f", *o["weights"])
                attrs["JOINTS_0"] = w.add_accessor(w.add_view(jn), 5123, n, "VEC4")
                attrs["WEIGHTS_0"] = w.add_accessor(w.add_view(wt), 5126, n, "VEC4")
            tex = o["materials"][0]["texture"] if o["materials"] else ""
            mat = w.material(f"obj{o['id']:02d}_{o['type']}", tex)
            w.meshes.append({"name": f"g{gi}_obj{o['id']:02d}_{o['type']}",
                             "primitives": [{"attributes": attrs, "indices": ia,
                                             "material": mat, "mode": 4}]})
            node: dict = {"name": f"g{gi}_obj{o['id']:02d}", "mesh": len(w.meshes) - 1}
            if o["local_tm"] != [1 if i % 5 == 0 else 0 for i in range(16)]:
                node["matrix"] = o["local_tm"]
            w.nodes.append(node)

    gltf = {
        "asset": {"version": "2.0", "generator": "aethermere o3d_to_glb"},
        "scene": 0,
        "scenes": [{"nodes": list(range(len(w.nodes)))}],
        "nodes": w.nodes,
        "meshes": w.meshes,
        "materials": w.materials,
        "accessors": w.accessors,
        "bufferViews": w.views,
        "buffers": [{"byteLength": len(w.bin)}],
    }
    j = _pad(json.dumps(gltf, separators=(",", ":")).encode(), b" ")
    b = _pad(bytes(w.bin), b"\x00")
    total = 12 + 8 + len(j) + (8 + len(b) if b else 0)
    out = struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(j), 0x4E4F534A) + j
    if b:
        out += struct.pack("<II", len(b), 0x004E4942) + b
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convierte .o3d a .glb")
    ap.add_argument("--input", required=True)
    ap.add_argument("--output")
    ap.add_argument("--output-dir")
    ap.add_argument("--group", type=int, default=0,
                    help="Grupo LOD a exportar (0 = primero, -1 = todos)")
    args = ap.parse_args(argv)
    paths = sorted(glob.glob(args.input)) if any(x in args.input for x in "*?[") else [args.input]
    paths = [p for p in paths if os.path.isfile(p)]
    if not paths:
        print(f"sin archivos: {args.input}", file=sys.stderr)
        return 1
    if len(paths) > 1 and not args.output_dir:
        print("multiples inputs requieren --output-dir", file=sys.stderr)
        return 1
    fails = 0
    for p in paths:
        try:
            glb = convert(parse_o3d(p), group=args.group)
        except (OSError, ValueError, struct.error) as e:
            print(f"ERROR {p}: {e}", file=sys.stderr)
            fails += 1
            continue
        if args.output_dir:
            os.makedirs(args.output_dir, exist_ok=True)
            out = os.path.join(args.output_dir, os.path.splitext(os.path.basename(p))[0] + ".glb")
        elif args.output:
            out = args.output
        else:
            out = os.path.splitext(p)[0] + ".glb"
        with open(out, "wb") as f:
            f.write(glb)
        print(f"OK {p} -> {out} ({len(glb)} bytes)")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
