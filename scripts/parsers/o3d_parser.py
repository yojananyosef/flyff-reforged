#!/usr/bin/env python3
"""Parser de modelos .o3d del cliente FlyFF v21 -> JSON.

Reimplementacion en Python de ``LoadedObject::LoadObject/LoadGMObject``
del lector C++ de referencia (ver ``docs/o3d-research.md``):

    u8 name_len + nombre XOR 0xCD + u32 version + u32 id
    vec3 force1/2 (+ force3/4 si ver >= 22) + 2x f32 scroll + 16 reservados
    vec3 bb_min/max + f32 slerp + u32 max_frame + u32 max_event (+ eventos)
    u32 coll_flag (+ GMOBJECT si != 0)
    u32 lod_flag + u32 bone_count (+ huesos base + ReadTM si max_frame > 0)
    u32 pool_size + grupos LOD con objetos (tipo, huesos, localTM, GMOBJECT...)
    [ver >= 21: u32 nAttr (+ attrs si nAttr == max_frame)]

Por objeto (LoadGMObject): bbox, flags opacity/bump/rigid + 28 skip,
conteos, vertexList, VB (SKIN 44 / NORMAL 32, +12 si bump), IB+IIB u16,
physique opcional, materiales (GLWMATERIAL9 68 + nombre) y bloques (136).

Uso:
    python3 o3d_parser.py --input modelo.o3d --output modelo.json [--with-geometry]
    python3 o3d_parser.py --input "Model/*.o3d" --output-dir out/ --batch
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

VER_MESH_MIN = 20
MAX_NAME_LEN = 64
MAX_MTRLBLK = 32

SKIN_VSIZE = 44
NORMAL_VSIZE = 32
BUMP_EXTRA = 12
MATERIAL_SIZE = 68
MTRLBLK_SIZE = 136  # 3xi32 + u32 + i32 + i32 + 28xi32
TM_ANIM_SIZE = 28
MOTION_ATTR_SIZE = 12

GMTYPE = {-1: "ERROR", 0: "NORMAL", 1: "SKIN", 2: "BONE"}


class Cursor:
    def __init__(self, data: bytes, path: str):
        self.d = data
        self.off = 0
        self.path = path

    def need(self, n: int, what: str) -> None:
        if self.off + n > len(self.d):
            raise ValueError(f"{self.path}: EOF en {what} (off={self.off})")

    def u8(self) -> int:
        self.need(1, "u8")
        v = self.d[self.off]
        self.off += 1
        return v

    def u16(self) -> int:
        self.need(2, "u16")
        (v,) = struct.unpack_from("<H", self.d, self.off)
        self.off += 2
        return v

    def i32(self) -> int:
        self.need(4, "i32")
        (v,) = struct.unpack_from("<i", self.d, self.off)
        self.off += 4
        return v

    def u32(self) -> int:
        self.need(4, "u32")
        (v,) = struct.unpack_from("<I", self.d, self.off)
        self.off += 4
        return v

    def f32(self) -> float:
        self.need(4, "f32")
        (v,) = struct.unpack_from("<f", self.d, self.off)
        self.off += 4
        return float(v)

    def vec3(self) -> list[float]:
        self.need(12, "vec3")
        v = struct.unpack_from("<3f", self.d, self.off)
        self.off += 12
        return [float(x) for x in v]

    def mat4(self) -> list[float]:
        self.need(64, "mat4")
        v = struct.unpack_from("<16f", self.d, self.off)
        self.off += 64
        return [float(x) for x in v]

    def raw(self, n: int, what: str) -> bytes:
        self.need(n, what)
        b = self.d[self.off:self.off + n]
        self.off += n
        return b

    def skip(self, n: int, what: str) -> None:
        self.need(n, what)
        self.off += n

    def remaining(self) -> int:
        return len(self.d) - self.off


def parse_gmobject(c: Cursor, gtype: str) -> dict:
    bb_min = c.vec3()
    bb_max = c.vec3()
    opacity = c.u32()
    bump = c.u32()
    rigid = c.u32()
    c.skip(28, "gmobject reservados")
    n_vlist = c.u32()
    n_vb = c.u32()
    n_facelist = c.u32()
    n_ib = c.u32()
    for name, v in (("vertex_list", n_vlist), ("vb", n_vb), ("ib", n_ib)):
        if v > 1_000_000:
            raise ValueError(f"{c.path}: conteo {name} absurdo ({v})")

    vertex_list = [c.vec3() for _ in range(n_vlist)]

    # NOTA: el flag bump NO cambia el tamano de vertice en estos archivos
    # (verificado por cuadre exacto; el lector C++ tambien lo ignora).
    # SKIN = 44 (pos+pesos+matIdx+normal+uv), NORMAL = 32 (pos+normal+uv).
    vsize = SKIN_VSIZE if gtype == "SKIN" else NORMAL_VSIZE
    vb_raw = c.raw(n_vb * vsize, "vertex buffer")

    positions, normals, uvs, joints, weights = [], [], [], [], []
    for i in range(n_vb):
        o = i * vsize
        px, py, pz = struct.unpack_from("<3f", vb_raw, o)
        o += 12
        j0 = j1 = 0
        w0, w1 = 1.0, 0.0
        if gtype == "SKIN":
            w0, w1 = struct.unpack_from("<2f", vb_raw, o)
            o += 8
            (mat_idx,) = struct.unpack_from("<I", vb_raw, o)
            o += 4
            j0, j1 = mat_idx & 0xFFFF, (mat_idx >> 16) & 0xFFFF
        nx, ny, nz = struct.unpack_from("<3f", vb_raw, o)
        o += 12
        tu, tv = struct.unpack_from("<2f", vb_raw, o)
        positions += [px, py, pz]
        normals += [nx, ny, nz]
        uvs += [tu, tv]
        joints += [j0, j1, 0, 0]
        weights += [w0, w1, 0.0, 0.0]

    indices = [c.u16() for _ in range(n_ib)]
    iib = [c.u16() for _ in range(n_vb)]  # segundo buffer de indices (instancing)

    physique = None
    if c.u32():
        physique = list(struct.unpack_from(f"<{n_vlist}i", c.raw(n_vlist * 4, "physique")))

    materials = []
    if c.u32():
        n_mat = c.u32()
        if n_mat == 0:
            n_mat = 1
        if n_mat > 16:
            raise ValueError(f"{c.path}: materiales absurdos ({n_mat})")
        for _ in range(n_mat):
            mat = list(struct.unpack_from("<17f", c.raw(MATERIAL_SIZE, "material")))
            nlen = c.u32()
            if nlen > 256:
                raise ValueError(f"{c.path}: nombre de textura absurdo ({nlen})")
            tex = c.raw(nlen, "nombre textura").split(b"\x00")[0].decode("ascii", errors="replace")
            materials.append({"colors": mat, "texture": tex})

    n_blk = c.u32()
    if n_blk >= MAX_MTRLBLK:
        raise ValueError(f"{c.path}: bloques de material absurdos ({n_blk})")
    blocks = []
    for _ in range(n_blk):
        vals = struct.unpack_from("<6i28i", c.raw(MTRLBLK_SIZE, "bloque material"))
        blocks.append({"start_vertex": vals[0], "prim_count": vals[1],
                       "texture_id": vals[2], "effect": vals[3], "amount": vals[4]})

    return {
        "bbox": [bb_min, bb_max],
        "opacity": opacity, "bump": bool(bump), "rigid": bool(rigid),
        "counts": {"vertex_list": n_vlist, "vb": n_vb, "faces": n_facelist, "ib": n_ib},
        "vertex_size": vsize,
        "positions": positions, "normals": normals, "uvs": uvs,
        "joints": joints, "weights": weights,
        "indices": indices, "iib": iib,
        "has_physique": physique is not None,
        "materials": materials, "blocks": blocks,
    }


def parse_tm_bones(c: Cursor, n_bone: int, n_frame: int) -> list[dict]:
    """ReadTM del lector C++: hueso con nombre + 2 matrices + padre."""
    bones = []
    for i in range(n_bone):
        nlen = c.i32()
        if nlen <= 0 or nlen > MAX_NAME_LEN:
            raise ValueError(f"{c.path}: name_len de hueso TM invalido ({nlen})")
        name = c.raw(nlen, "nombre hueso TM").split(b"\x00")[0].decode("ascii", errors="replace")
        inv = c.mat4()
        loc = c.mat4()
        parent = c.i32()
        bones.append({"index": i, "name": name, "parent": parent,
                      "inverse": inv, "local": loc})
    anim_size = c.u32()
    counted = 0
    for b in bones:
        flag = c.i32()
        if flag == 1:
            frames = []
            for _ in range(n_frame):
                qx, qy, qz, qw, px, py, pz = struct.unpack_from("<7f", c.raw(TM_ANIM_SIZE, "frame TM"))
                frames.append({"rot": [qx, qy, qz, qw], "pos": [px, py, pz]})
                counted += 1
            b["animated"] = True
            b["frames"] = frames
        else:
            b["animated"] = False
            b["static_tm"] = c.mat4()
    if counted != anim_size:
        raise ValueError(f"{c.path}: ReadTM descuadra ({counted} != {anim_size})")
    return bones


def parse_o3d(path: str) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    c = Cursor(data, path)
    if len(data) < 8:
        raise ValueError(f"{path}: archivo demasiado pequeno")

    nlen = c.u8()
    if nlen == 0 or nlen >= MAX_NAME_LEN:
        raise ValueError(f"{path}: name_len invalido ({nlen})")
    inner = bytes(b ^ 0xCD for b in c.raw(nlen, "nombre interno")).decode("ascii", errors="replace")
    ver = c.u32()
    if ver < VER_MESH_MIN:
        raise ValueError(f"{path}: version {ver} < {VER_MESH_MIN}")
    file_id = c.u32()
    forces = [c.vec3(), c.vec3()]
    if ver >= 22:
        forces += [c.vec3(), c.vec3()]
    scroll = [c.f32(), c.f32()]
    c.skip(16, "reservados")
    bb_min, bb_max = c.vec3(), c.vec3()
    slerp = c.f32()
    max_frame = c.u32()
    max_event = c.u32()
    events = [c.vec3() for _ in range(max_event)]

    collision = None
    if c.u32():
        collision = parse_gmobject(c, "NORMAL")

    lod = c.u32()
    n_bone = c.u32()
    if n_bone > 512:
        raise ValueError(f"{path}: huesos absurdos ({n_bone})")
    base_bones = []
    tm_bones = []
    send_vs = 0
    if n_bone > 0:
        base_bones = [{"base": c.mat4(), "inv": c.mat4()} for _ in range(n_bone)]
        if max_frame > 0:
            tm_bones = parse_tm_bones(c, n_bone, max_frame)
        send_vs = c.u32()

    pool_size = c.u32()
    if pool_size > 4096:
        raise ValueError(f"{path}: pool absurdo ({pool_size})")
    groups = []
    for _g in range(3 if lod else 1):
        n_obj = c.u32()
        if n_obj > pool_size + 1:
            raise ValueError(f"{path}: objetos {n_obj} > pool {pool_size}")
        objects = []
        for _ in range(n_obj):
            ntype = c.u32()
            gtype = GMTYPE.get(ntype & 0xFFFF, f"UNKNOWN({ntype & 0xFFFF})")
            if gtype.startswith("UNKNOWN"):
                raise ValueError(f"{path}: tipo de objeto desconocido ({ntype:#x})")
            light = bool(ntype & 0x80000000)
            n_use = c.u32()
            if n_use > 256:
                raise ValueError(f"{path}: useBone absurdo ({n_use})")
            usebones = [c.u32() for _ in range(n_use)]
            obj_id = c.u32()
            parent_idx = c.i32()
            parent_type = None
            if parent_idx != -1:
                parent_type = GMTYPE.get(c.u32() & 0xFFFF, "?")
            local_tm = c.mat4()
            geo = parse_gmobject(c, gtype if gtype in ("SKIN", "NORMAL") else "NORMAL")
            tm_frames = None
            if gtype == "NORMAL" and max_frame > 0:
                flag = c.i32()
                if flag == 1:
                    tm_frames = []
                    for _ in range(max_frame):
                        q = struct.unpack_from("<7f", c.raw(TM_ANIM_SIZE, "frame objeto"))
                        tm_frames.append({"rot": list(q[:4]), "pos": list(q[4:])})
            # validacion de indices
            bad = [ix for ix in geo["indices"] if ix >= geo["counts"]["vb"]]
            objects.append({
                "id": obj_id, "type": gtype, "light": light,
                "use_bones": usebones, "parent": parent_idx, "parent_type": parent_type,
                "local_tm": local_tm, "tm_frames": tm_frames,
                "bad_indices": len(bad), **geo,
            })
        groups.append({"object_count": n_obj, "objects": objects})

    attrs = []
    # NOTA: el bloque nAttr no siempre existe (el lector C++ lee de mas
    # sin comprobar EOF). Solo se consume si hay bytes suficientes.
    if ver >= 21 and c.remaining() >= 4:
        n_attr = c.u32()
        if n_attr == max_frame and max_frame > 0 and c.remaining() >= max_frame * MOTION_ATTR_SIZE:
            for _ in range(max_frame):
                attr, snd, frm = struct.unpack_from("<Iif", c.raw(MOTION_ATTR_SIZE, "attr"))
                if attr or snd:
                    attrs.append({"attr": attr, "snd_id": snd, "frame": frm})

    return {
        "source_file": os.path.basename(path),
        "format": "flyff_o3d",
        "inner_name": inner,
        "version": ver,
        "file_id": file_id,
        "forces": forces,
        "scroll": scroll,
        "bbox": [bb_min, bb_max],
        "per_slerp": slerp,
        "max_frame": max_frame,
        "max_event": max_event,
        "has_collision": collision is not None,
        "lod": bool(lod),
        "base_bones": len(base_bones),
        "tm_bones": len(tm_bones),
        "send_vs": send_vs,
        "pool_size": pool_size,
        "groups": groups,
        "attrs": attrs,
        "trailing_bytes": c.remaining(),
    }


def summarize(result: dict) -> dict:
    objs = [o for g in result["groups"] for o in g["objects"]]
    return {
        "file": result["source_file"],
        "ver": result["version"],
        "objects": len(objs),
        "types": sorted({o["type"] for o in objs}),
        "verts": sum(o["counts"]["vb"] for o in objs),
        "tris": sum(o["counts"]["ib"] for o in objs) // 3,
        "bad_indices": sum(o["bad_indices"] for o in objs),
        "trailing": result["trailing_bytes"],
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convierte .o3d FlyFF a JSON")
    ap.add_argument("--input", required=True)
    ap.add_argument("--output")
    ap.add_argument("--output-dir")
    ap.add_argument("--with-geometry", action="store_true",
                    help="Incluye arrays de geometria (grande)")
    ap.add_argument("--batch", action="store_true",
                    help="Modo batch: resumen por archivo + estadisticas")
    args = ap.parse_args(argv)

    paths = sorted(glob.glob(args.input)) if any(x in args.input for x in "*?[") else [args.input]
    paths = [p for p in paths if os.path.isfile(p)]
    if not paths:
        print(f"sin archivos: {args.input}", file=sys.stderr)
        return 1
    if len(paths) > 1 and not args.output_dir and not args.batch:
        print("multiples inputs requieren --output-dir o --batch", file=sys.stderr)
        return 1

    stats = {"ok": 0, "exact": 0, "fail": 0, "failures": []}
    for p in paths:
        try:
            result = parse_o3d(p)
        except (OSError, ValueError, struct.error) as e:
            stats["fail"] += 1
            stats["failures"].append(f"{os.path.basename(p)}: {e}")
            if not args.batch:
                print(f"ERROR {p}: {e}", file=sys.stderr)
            continue
        stats["ok"] += 1
        if result["trailing_bytes"] == 0:
            stats["exact"] += 1
        if args.batch:
            s = summarize(result)
            print(f"OK {s['file']} v{s['ver']} objs={s['objects']} {s['types']} "
                  f"v={s['verts']} tri={s['tris']} bad={s['bad_indices']} trail={s['trailing']}")
            continue
        if not args.with_geometry:
            for g in result["groups"]:
                for o in g["objects"]:
                    for k in ("positions", "normals", "uvs", "joints", "weights",
                              "indices", "iib"):
                        o[k] = f"<{len(o[k])} valores>"
        if args.output_dir:
            os.makedirs(args.output_dir, exist_ok=True)
            out = os.path.join(args.output_dir, os.path.splitext(os.path.basename(p))[0] + ".json")
        elif args.output:
            out = args.output
        else:
            out = os.path.splitext(p)[0] + ".json"
        with open(out, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=1)
        print(f"OK {p} -> {out}")
    if args.batch or len(paths) > 1:
        print(f"BATCH: ok={stats['ok']} exactos={stats['exact']} fallos={stats['fail']}",
              file=sys.stderr if stats["fail"] else sys.stdout)
        for fl in stats["failures"][:20]:
            print(f"  FALLO {fl}")
    return 1 if stats["fail"] else 0


if __name__ == "__main__":
    sys.exit(main())
