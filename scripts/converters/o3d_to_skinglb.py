#!/usr/bin/env python3
"""Convierte personaje FlyFF (.o3d + .chr + .ani) a .glb animado.

Evidencia (ver design aethermere-skin):
  - m1 = inversa de m0; m2 = matriz local (orden L*P, row-major D3D).
  - articulacion = usebones[matIdx // 3]; nombres .ani == .chr.
  - matrices traspuestas a column-major glTF; quats tal cual.

Uso:
    python3 o3d_to_skinglb.py --o3d M.o3d --chr M.chr --anis "M_*.ani" --output M.glb
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "..", "parsers"))
from o3d_parser import parse_o3d  # noqa: E402
from chr_parser import parse_chr  # noqa: E402
from ani_parser import parse_ani  # noqa: E402

FPS = 30.0


def transpose(m: list[float]) -> list[float]:
    return [m[r + 4 * c] for c in range(4) for r in range(4)]


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
                     minimum: list | None = None, maximum: list | None = None) -> int:
        idx = len(self.accessors)
        acc: dict = {"bufferView": view, "componentType": comp, "count": count, "type": atype}
        if minimum is not None:
            acc["min"] = minimum
            acc["max"] = maximum
        self.accessors.append(acc)
        return idx


def build(o3d_path: str, chr_path: str, ani_paths: list[str]) -> bytes:
    o = parse_o3d(o3d_path)
    c = parse_chr(chr_path)
    bones = c["bones"]
    n_bone = len(bones)
    w = GlbWriter()
    nodes: list[dict] = []
    children: list[list] = [[] for _ in range(n_bone)]
    roots: list[int] = []
    for i, b in enumerate(bones):
        p = b["parent"]
        if p == -1:
            roots.append(i)
        else:
            children[p].append(i)
    for i, b in enumerate(bones):
        node: dict = {"name": b["name"], "matrix": transpose(b["m2"])}
        if children[i]:
            node["children"] = children[i]
        nodes.append(node)

    # skin: joints = todos los huesos en orden .chr
    ibm_data = b"".join(struct.pack("<16f", *transpose(b["m1"])) for b in bones)
    ibm_acc = w.add_accessor(w.add_view(ibm_data), 5126, n_bone, "MAT4")
    skin = {"inverseBindMatrices": ibm_acc, "joints": list(range(n_bone)),
            "skeleton": roots[0]}

    meshes: list[dict] = []
    mesh_nodes: list[int] = []
    materials: list[dict] = []
    ub_cache: dict[str, int] = {}

    def material(tex: str, tag: str) -> int:
        key = tag + "|" + tex
        if key in ub_cache:
            return ub_cache[key]
        idx = len(materials)
        materials.append({
            "name": tag,
            "pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1],
                                     "metallicFactor": 0.0, "roughnessFactor": 0.9},
            "extras": {"flyff_texture": tex}})
        ub_cache[key] = idx
        return idx

    groups = o["groups"][:1]  # grupo LOD 0
    for gi, group in enumerate(groups):
        for ob in group["objects"]:
            n = ob["counts"]["vb"]
            if n == 0 or not ob["indices"]:
                continue
            pos = struct.pack(f"<{len(ob['positions'])}f", *ob["positions"])
            nor = struct.pack(f"<{len(ob['normals'])}f", *ob["normals"])
            uv = struct.pack(f"<{len(ob['uvs'])}f", *ob["uvs"])
            idx_max = max(ob["indices"])
            fmt = "<H" if idx_max < 65536 else "<I"
            idx = struct.pack(f"{fmt[0]}{len(ob['indices'])}{fmt[1]}", *ob["indices"])
            ub = ob["use_bones"]
            jn, wt = [], []
            for i in range(n):
                j0 = ob["joints"][i * 4] // 3
                j1 = ob["joints"][i * 4 + 1] // 3
                w0, w1 = ob["weights"][i * 4], ob["weights"][i * 4 + 1]
                b0 = ub[j0] if 0 <= j0 < len(ub) else 0
                b1 = ub[j1] if 0 <= j1 < len(ub) else 0
                s = w0 + w1
                if s <= 0:
                    w0, w1, s = 1.0, 0.0, 1.0
                jn += [b0, b1, 0, 0]
                wt += [w0 / s, w1 / s, 0.0, 0.0]
            jdat = struct.pack(f"<{len(jn)}H", *[int(x) & 0xFFFF for x in jn])
            wdat = struct.pack(f"<{len(wt)}f", *wt)
            ia = w.add_accessor(w.add_view(idx), 5123 if fmt == "<H" else 5125,
                                len(ob["indices"]), "SCALAR")
            pa = w.add_accessor(
                w.add_view(pos), 5126, n, "VEC3",
                [min(ob["positions"][k::3]) for k in range(3)],
                [max(ob["positions"][k::3]) for k in range(3)])
            na = w.add_accessor(w.add_view(nor), 5126, n, "VEC3")
            ta = w.add_accessor(w.add_view(uv), 5126, n, "VEC2")
            ja = w.add_accessor(w.add_view(jdat), 5123, n, "VEC4")
            wa = w.add_accessor(w.add_view(wdat), 5126, n, "VEC4")
            tex = ob["materials"][0]["texture"] if ob["materials"] else ""
            mat = material(tex, f"obj{ob['id']:02d}_{ob['type']}")
            meshes.append({"name": f"g{gi}_obj{ob['id']:02d}_{ob['type']}",
                           "primitives": [{"attributes": {
                               "POSITION": pa, "NORMAL": na, "TEXCOORD_0": ta,
                               "JOINTS_0": ja, "WEIGHTS_0": wa},
                               "indices": ia, "material": mat, "mode": 4}]})
            mesh_nodes.append(len(nodes))
            nodes.append({"name": f"g{gi}_obj{ob['id']:02d}", "mesh": len(meshes) - 1,
                          "skin": 0})

    animations: list[dict] = []
    base = os.path.splitext(os.path.basename(o3d_path))[0].lower()
    for ap in sorted(ani_paths):
        stem = os.path.splitext(os.path.basename(ap))[0]
        aname = stem[len(base) + 1:] if stem.lower().startswith(base + "_") else stem
        a = parse_ani(ap)
        abones = {b["name"]: b for b in a["bones"]}
        name_to_node = {b["name"]: i for i, b in enumerate(bones)}
        nframes = a["frame_count"]
        times = struct.pack(f"<{nframes}f", *[i / FPS for i in range(nframes)])
        t_acc = w.add_accessor(w.add_view(times), 5126, nframes, "SCALAR",
                               [0.0], [(nframes - 1) / FPS])
        channels, samplers = [], []
        for bname, ab in abones.items():
            if bname not in name_to_node or not ab.get("animated"):
                continue
            fr = ab["frames"]
            rots = b"".join(struct.pack("<4f", *f["rot"]) for f in fr)
            poss = b"".join(struct.pack("<3f", *f["pos"]) for f in fr)
            r_acc = w.add_accessor(w.add_view(rots), 5126, nframes, "VEC4")
            p_acc = w.add_accessor(w.add_view(poss), 5126, nframes, "VEC3")
            node = name_to_node[bname]
            samplers.append({"input": t_acc, "output": r_acc, "interpolation": "LINEAR"})
            channels.append({"sampler": len(samplers) - 1,
                             "target": {"node": node, "path": "rotation"}})
            samplers.append({"input": t_acc, "output": p_acc, "interpolation": "LINEAR"})
            channels.append({"sampler": len(samplers) - 1,
                             "target": {"node": node, "path": "translation"}})
        if channels:
            animations.append({"name": aname, "channels": channels, "samplers": samplers})

    gltf = {
        "asset": {"version": "2.0", "generator": "aethermere o3d_to_skinglb"},
        "scene": 0,
        "scenes": [{"nodes": roots + mesh_nodes}],
        "nodes": nodes,
        "meshes": meshes,
        "skins": [skin],
        "materials": materials,
        "animations": animations,
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
    ap = argparse.ArgumentParser(description="Convierte personaje FlyFF a .glb animado")
    ap.add_argument("--o3d", required=True)
    ap.add_argument("--chr", required=True)
    ap.add_argument("--anis", required=True, help="Patron glob de .ani")
    ap.add_argument("--output", required=True)
    args = ap.parse_args(argv)
    anis = sorted(glob.glob(args.anis))
    if not anis:
        print(f"sin animaciones: {args.anis}", file=sys.stderr)
        return 1
    try:
        glb = build(args.o3d, args.chr, anis)
    except (OSError, ValueError, struct.error) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    with open(args.output, "wb") as f:
        f.write(glb)
    print(f"OK {args.o3d} + {len(anis)} anis -> {args.output} ({len(glb)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
