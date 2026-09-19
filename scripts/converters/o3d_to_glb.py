#!/usr/bin/env python3
"""Convierte .o3d FlyFF a .glb (glTF 2.0 binario) sin dependencias.

Geometria por GMOBJECT: POSITION/NORMAL/TEXCOORD_0, INDICES u16 (u32 si
hace falta), JOINTS_0/WEIGHTS_0 si es SKIN. Un material por objeto con
el nombre de la textura FlyFF en ``extras``; con --tex-dir se embebe
el PNG convertido de cada .dds como baseColorTexture.

Uso:
    python3 o3d_to_glb.py --input modelo.o3d --output modelo.glb
    python3 o3d_to_glb.py --input "Model/*.o3d" --output-dir out/
    python3 o3d_to_glb.py --input modelo.o3d --output modelo.glb --tex-dir tex_png/
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
        self.images: list[dict] = []
        self.samplers: list[dict] = []
        self.textures: list[dict] = []
        self.tex_cache: dict[str, int] = {}
        self.pngs: dict[str, bytes] = {}

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

    def set_tex_dir(self, tex_dir: str | None) -> None:
        """Carga los <textura>.png preparados (DDS del cliente -> RGBA)."""
        if not tex_dir or not os.path.isdir(tex_dir):
            return
        for fn in sorted(os.listdir(tex_dir)):
            if fn.lower().endswith(".png"):
                with open(os.path.join(tex_dir, fn), "rb") as f:
                    self.pngs[os.path.splitext(fn)[0].lower()] = f.read()

    def texture_of(self, texture: str) -> int | None:
        """Embebe el PNG de una textura FlyFF o devuelve None (repliegue)."""
        import os as _os
        key = _os.path.splitext(_os.path.basename(texture))[0].lower()
        if key in self.tex_cache:
            return self.tex_cache[key]
        if key not in self.pngs:
            print(f"aviso: sin PNG para {texture} (pieza en blanco)")
            return None
        img_view = self.add_view(self.pngs[key])
        self.images.append({"bufferView": img_view, "mimeType": "image/png",
                            "name": key})
        if not self.samplers:
            self.samplers.append({"magFilter": 9729, "minFilter": 9987,
                                  "wrapS": 10497, "wrapT": 10497})
        self.textures.append({"source": len(self.images) - 1, "sampler": 0})
        self.tex_cache[key] = len(self.textures) - 1
        return self.tex_cache[key]

    def material(self, name: str, texture: str) -> int:
        key = name + "|" + texture
        if key in self.mat_cache:
            return self.mat_cache[key]
        idx = len(self.materials)
        pbr: dict = {"baseColorFactor": [1, 1, 1, 1],
                     "metallicFactor": 0.0, "roughnessFactor": 0.9}
        if texture:
            ti = self.texture_of(texture)
            if ti is not None:
                pbr["baseColorTexture"] = {"index": ti, "texCoord": 0}
        self.materials.append({
            "name": name,
            "pbrMetallicRoughness": pbr,
            "extras": {"flyff_texture": texture},
        })
        self.mat_cache[key] = idx
        return idx


def convert(parsed: dict, group: int = 0, tex_dir: str | None = None) -> bytes:
    w = GlbWriter()
    w.set_tex_dir(tex_dir)
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
            # Un objeto puede mezclar materiales por bloques (start/prims
            # acumulan el index buffer en orden): una primitiva por bloque.
            tex_list = o.get("materials", [])
            blocks = o.get("blocks", [])
            splits: list[tuple[str, list]] = []
            if blocks and tex_list and sum(
                    b["prim_count"] * 3 for b in blocks) == len(o["indices"]):
                off = 0
                for b in blocks:
                    cnt = b["prim_count"] * 3
                    tid = b["texture_id"]
                    tex = tex_list[tid]["texture"] \
                        if 0 <= tid < len(tex_list) else ""
                    splits.append((tex, o["indices"][off:off + cnt]))
                    off += cnt
            else:
                tex0 = tex_list[0]["texture"] if tex_list else ""
                splits = [(tex0, o["indices"])]
            for tex, chunk in splits:
                if not chunk:
                    continue
                cmax = max(chunk)
                cfmt = "<H" if cmax < 65536 else "<I"
                cidx = struct.pack(f"{cfmt[0]}{len(chunk)}{cfmt[1]}", *chunk)
                ia = w.add_accessor(
                    w.add_view(cidx), 5123 if cfmt == "<H" else 5125,
                    len(chunk), "SCALAR")
                mat = w.material(f"obj{o['id']:02d}_{o['type']}", tex)
                w.meshes.append({"name": f"g{gi}_obj{o['id']:02d}_{o['type']}",
                                 "primitives": [{"attributes": attrs,
                                                 "indices": ia,
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
    if w.images:
        gltf["images"] = w.images
        gltf["samplers"] = w.samplers
        gltf["textures"] = w.textures
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
    ap.add_argument("--tex-dir", default=None,
                    help="Dir con <textura>.png (DDS del cliente ya convertidos)")
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
            glb = convert(parse_o3d(p), group=args.group, tex_dir=args.tex_dir)
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
