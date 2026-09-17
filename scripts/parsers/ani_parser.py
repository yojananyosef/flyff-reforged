#!/usr/bin/env python3
"""Parser de animaciones .ani del cliente FlyFF v21 -> JSON.

Formato (verificado contra archivos reales + ``CMotion::LoadMotion`` /
``ReadTM`` del lector C++ de referencia):
    u32 version      (10)
    u32 id
    f32 per_slerp    (0.5)
    32 bytes reservados
    u32 bone_count
    u32 frame_count
    u32 path_flag    (0/1; si 1: frame_count x vec3)
    huesos[bone_count]: u32 name_len + char[] + mat4 inverse + mat4 local + i32 parent
    u32 anim_size    (total de frames con animacion)
    por hueso: i32 flag (1 = frame_count x {quat(4f)+pos(3f)}; 0 = mat4 local estatico)
    attrs[frame_count]: {u32 attr, i32 snd_id, f32 frame}
    u32 max_event (+ eventos si > 0)

Uso:
    python3 ani_parser.py --input anim.ani --output anim.json
    python3 ani_parser.py --input "app/Model/*.ani" --output-dir assets/animations/
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

VERSION_EXPECTED = 10
TM_ANIM_SIZE = 28  # quat(16) + pos(12)
MAT4_SIZE = 64
MAX_NAME_LEN = 64


def parse_ani(path: str, include_frames: bool = True) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 56:
        raise ValueError(f"{path}: archivo demasiado pequeno ({len(data)} bytes)")

    off = 0
    (version, file_id) = struct.unpack_from("<2I", data, off)
    off += 8
    if version != VERSION_EXPECTED:
        raise ValueError(f"{path}: version inesperada {version} (esperada {VERSION_EXPECTED})")
    (per_slerp,) = struct.unpack_from("<f", data, off)
    off += 4 + 32  # slerp + reservados
    bone_count, frame_count, path_flag = struct.unpack_from("<3I", data, off)
    off += 12
    if bone_count > 512 or frame_count > 10000:
        raise ValueError(f"{path}: conteos absurdos (huesos={bone_count} frames={frame_count})")

    path_data = None
    if path_flag:
        need = frame_count * 12
        if off + need > len(data):
            raise ValueError(f"{path}: EOF en path data")
        path_data = list(struct.unpack_from(f"<{frame_count * 3}f", data, off))
        off += need

    bones: list[dict] = []
    for i in range(bone_count):
        if off + 4 > len(data):
            raise ValueError(f"{path}: EOF en name_len del hueso {i}")
        (name_len,) = struct.unpack_from("<I", data, off)
        off += 4
        if name_len <= 0 or name_len > MAX_NAME_LEN:
            raise ValueError(f"{path}: name_len invalido ({name_len}) hueso {i}")
        raw = data[off : off + name_len]
        off += name_len
        name = raw.split(b"\x00")[0].decode("ascii", errors="replace")
        if off + MAT4_SIZE * 2 + 4 > len(data):
            raise ValueError(f"{path}: EOF en matrices del hueso '{name}'")
        inv = list(struct.unpack_from("<16f", data, off))
        off += MAT4_SIZE
        loc = list(struct.unpack_from("<16f", data, off))
        off += MAT4_SIZE
        (parent,) = struct.unpack_from("<i", data, off)
        off += 4
        bones.append({"index": i, "name": name, "parent": parent,
                      "inverse": inv, "local": loc})

    if off + 4 > len(data):
        raise ValueError(f"{path}: EOF en anim_size")
    (anim_size,) = struct.unpack_from("<I", data, off)
    off += 4

    animated_total = 0
    for b in bones:
        if off + 4 > len(data):
            raise ValueError(f"{path}: EOF en flag de animacion de '{b['name']}'")
        (flag,) = struct.unpack_from("<i", data, off)
        off += 4
        if flag == 1:
            need = frame_count * TM_ANIM_SIZE
            if off + need > len(data):
                raise ValueError(f"{path}: EOF en frames de '{b['name']}'")
            frames = []
            if include_frames:
                for _ in range(frame_count):
                    qx, qy, qz, qw, px, py, pz = struct.unpack_from("<7f", data, off)
                    frames.append({"rot": [qx, qy, qz, qw], "pos": [px, py, pz]})
                    off += TM_ANIM_SIZE
            else:
                off += need
            b["animated"] = True
            if include_frames:
                b["frames"] = frames
            animated_total += frame_count
        else:
            if off + MAT4_SIZE > len(data):
                raise ValueError(f"{path}: EOF en TM estatico de '{b['name']}'")
            b["animated"] = False
            b["static_tm"] = list(struct.unpack_from("<16f", data, off))
            off += MAT4_SIZE

    attrs = []
    for _ in range(frame_count):
        if off + 12 > len(data):
            raise ValueError(f"{path}: EOF en attrs")
        attr, snd_id, frm = struct.unpack_from("<Iif", data, off)
        off += 12
        if attr or snd_id:
            attrs.append({"attr": attr, "snd_id": snd_id, "frame": frm})

    max_event = 0
    if off + 4 <= len(data):
        (max_event,) = struct.unpack_from("<I", data, off)
        off += 4
        off += max_event * 12  # eventos vec3 (se omiten, solo se consumen)

    return {
        "source_file": os.path.basename(path),
        "format": "flyff_ani",
        "version": version,
        "file_id": file_id,
        "per_slerp": per_slerp,
        "bone_count": bone_count,
        "frame_count": frame_count,
        "has_path": bool(path_flag),
        "anim_size_declared": anim_size,
        "anim_frames_counted": animated_total,
        "anim_size_match": animated_total == anim_size,
        "bones": bones,
        "attrs": attrs,
        "max_event": max_event,
        "trailing_bytes": len(data) - off,
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convierte .ani FlyFF a JSON")
    ap.add_argument("--input", required=True)
    ap.add_argument("--output")
    ap.add_argument("--output-dir")
    ap.add_argument("--no-frames", action="store_true",
                    help="Omite keyframes (solo estructura)")
    args = ap.parse_args(argv)

    paths = sorted(glob.glob(args.input)) if any(c in args.input for c in "*?[") else [args.input]
    paths = [p for p in paths if os.path.isfile(p)]
    if not paths:
        print(f"sin archivos: {args.input}", file=sys.stderr)
        return 1
    if len(paths) > 1 and not args.output_dir:
        print("multiples inputs requieren --output-dir", file=sys.stderr)
        return 1

    failures = 0
    for p in paths:
        try:
            result = parse_ani(p, include_frames=not args.no_frames)
            if not result["anim_size_match"]:
                print(f"WARN {p}: anim_size {result['anim_size_declared']} != contados {result['anim_frames_counted']}",
                      file=sys.stderr)
        except (OSError, ValueError, struct.error) as e:
            print(f"ERROR {p}: {e}", file=sys.stderr)
            failures += 1
            continue
        if args.output_dir:
            os.makedirs(args.output_dir, exist_ok=True)
            out = os.path.join(args.output_dir,
                               os.path.splitext(os.path.basename(p))[0] + ".json")
        elif args.output:
            out = args.output
        else:
            out = os.path.splitext(p)[0] + ".json"
        with open(out, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2)
        print(f"OK {p} -> {out} ({result['bone_count']} huesos, {result['frame_count']} frames)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
