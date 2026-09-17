#!/usr/bin/env python3
"""Parser de esqueletos .chr del cliente FlyFF v21 -> JSON.

Formato (reverse engineering verificado contra archivos reales + lector C++
de referencia ``~/flyff-work/o3d-reader``):
    u32 version      (7)
    u32 id/hash
    u32 bone_count
    huesos[num]: u32 name_len + char[name_len] + mat4 x3 (192 bytes) + i32 parent_idx
    resto: terminador + padding (se ignora)

Las 3 matrices por hueso se guardan como ``m0``, ``m1``, ``m2``
(inversa/local/world segun contexto; se preservan las 3 sin interpretar).

Uso:
    python3 chr_parser.py --input Modelo.chr --output esqueleto.json
    python3 chr_parser.py --input "app/Model/*.chr" --output-dir assets/skeletons/
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import struct
import sys

VERSIONS_SUPPORTED = (4, 7)
MAT4_SIZE = 64  # 16 x float32
MAX_NAME_LEN = 64


def _read_mat4(data: bytes, off: int) -> tuple[list[float], int]:
    vals = struct.unpack_from("<16f", data, off)
    return [float(v) for v in vals], off + MAT4_SIZE


def parse_chr(path: str) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 12:
        raise ValueError(f"{path}: archivo demasiado pequeno ({len(data)} bytes)")

    version, file_id, bone_count = struct.unpack_from("<3I", data, 0)
    if version not in VERSIONS_SUPPORTED:
        raise ValueError(f"{path}: version inesperada {version} (soportadas {VERSIONS_SUPPORTED})")
    if bone_count > 512:
        raise ValueError(f"{path}: bone_count absurdo ({bone_count})")

    off = 12
    bones: list[dict] = []
    for i in range(bone_count):
        if off + 4 > len(data):
            raise ValueError(f"{path}: EOF al leer name_len del hueso {i}")
        (name_len,) = struct.unpack_from("<i", data, off)
        off += 4
        if name_len <= 0 or name_len > MAX_NAME_LEN:
            raise ValueError(
                f"{path}: name_len invalido ({name_len}) en hueso {i} off={off - 4}"
            )
        if off + name_len > len(data):
            raise ValueError(f"{path}: EOF al leer nombre del hueso {i}")
        raw_name = data[off : off + name_len]
        off += name_len
        name = raw_name.split(b"\x00")[0].decode("ascii", errors="replace")

        if off + MAT4_SIZE * 3 + 4 > len(data):
            raise ValueError(f"{path}: EOF al leer matrices del hueso '{name}'")
        m0, off = _read_mat4(data, off)
        m1, off = _read_mat4(data, off)
        m2, off = _read_mat4(data, off)
        (parent,) = struct.unpack_from("<i", data, off)
        off += 4
        bones.append(
            {"index": i, "name": name, "parent": parent, "m0": m0, "m1": m1, "m2": m2}
        )

    return {
        "source_file": os.path.basename(path),
        "format": "flyff_chr",
        "version": version,
        "file_id": file_id,
        "bone_count": bone_count,
        "bones": bones,
        "trailing_bytes": len(data) - off,
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convierte .chr FlyFF a JSON")
    ap.add_argument("--input", required=True, help="Archivo .chr o patron glob")
    ap.add_argument("--output", help="Archivo JSON de salida (un solo input)")
    ap.add_argument("--output-dir", help="Directorio de salida (multiples inputs)")
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
            result = parse_chr(p)
        except (OSError, ValueError, struct.error) as e:
            print(f"ERROR {p}: {e}", file=sys.stderr)
            failures += 1
            continue
        if args.output_dir:
            os.makedirs(args.output_dir, exist_ok=True)
            out = os.path.join(
                args.output_dir, os.path.splitext(os.path.basename(p))[0] + ".json"
            )
        elif args.output:
            out = args.output
        else:
            out = os.path.splitext(p)[0] + ".json"
        with open(out, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2)
        print(f"OK {p} -> {out} ({len(result['bones'])} huesos)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
