#!/usr/bin/env python3
"""Extracción de archivos .res del cliente FlyFF v21.

Formato (reimplementado desde Francesco149/flyfftools `flyffres.c`):
    u8  crypt_key    # clave del descifrado
    u8  is_crypt     # 1 = contenidos cifrados (la cabecera siempre lo va)
    u32 hdr_size     # tamaño de la cabecera cifrada
    cabecera: 7 bytes version (p. ej. '"V0.01"') + u16 num_files +
        por fichero: u16 name_len + nombre + u32 size + u32 mtime + u32 offset
    contenidos en `offset` (descifrados si is_crypt).

Descifrado por byte: `d = ~b ^ key; (d << 4 | d >> 4) & 0xFF`.

Uso:
    python3 res_parser.py --res WdMadrigal_10-15.res --out-dir ./tex
    python3 res_parser.py --res WdMadrigal_10-15.res --list
"""

from __future__ import annotations

import argparse
import os
import struct
import sys

VERSION_LEN = 7


def res_decrypt(key: int, data: bytes) -> bytes:
    out = bytearray(len(data))
    for i, b in enumerate(data):
        d = (~b & 0xFF) ^ key
        out[i] = ((d << 4) | (d >> 4)) & 0xFF
    return bytes(out)


def list_res(path: str) -> tuple[str, list[dict]]:
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 6:
        raise ValueError(f"{path}: demasiado corto ({len(data)} B)")
    key, is_crypt, hdr_size = struct.unpack_from("<BBI", data, 0)
    if 6 + hdr_size > len(data):
        raise ValueError(f"{path}: cabecera {hdr_size} B fuera del archivo")
    hdr = res_decrypt(key, data[6 : 6 + hdr_size])
    version = hdr[:VERSION_LEN].decode("ascii", errors="replace")
    num_files = struct.unpack_from("<H", hdr, VERSION_LEN)[0]
    entries: list[dict] = []
    p = VERSION_LEN + 2
    for _ in range(num_files):
        name_len = struct.unpack_from("<H", hdr, p)[0]
        p += 2
        name = hdr[p : p + name_len].decode("ascii", errors="replace")
        p += name_len
        size, mtime, offset = struct.unpack_from("<III", hdr, p)
        p += 12
        if offset + size > len(data):
            raise ValueError(f"{path}: {name} fuera del archivo")
        entries.append({"name": name, "size": size,
                        "mtime": mtime, "offset": offset})
    return version, entries


def extract_res(path: str, out_dir: str, only: set[str] | None = None) -> list[str]:
    with open(path, "rb") as f:
        data = f.read()
    key, is_crypt = struct.unpack_from("<BB", data, 0)
    _, entries = list_res(path)
    os.makedirs(out_dir, exist_ok=True)
    got = []
    for e in entries:
        if only is not None and e["name"] not in only:
            continue
        chunk = data[e["offset"] : e["offset"] + e["size"]]
        if is_crypt:
            chunk = res_decrypt(key, chunk)
        with open(os.path.join(out_dir, e["name"]), "wb") as f:
            f.write(chunk)
        os.utime(os.path.join(out_dir, e["name"]),
                  (e["mtime"], e["mtime"]))
        got.append(e["name"])
    return got


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Extrae archivos .res de FlyFF")
    ap.add_argument("--res", required=True)
    ap.add_argument("--out-dir", default="./flyff")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--only", nargs="*",
                    help="Solo estos ficheros (por nombre)")
    args = ap.parse_args(argv)
    try:
        if args.list:
            version, entries = list_res(args.res)
            print(f"version: {version}")
            for e in entries:
                print(f"{e['name']} ({e['size']} B)")
            return 0
        got = extract_res(args.res, args.out_dir,
                          set(args.only) if args.only else None)
    except (OSError, ValueError, struct.error) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print(f"OK {args.res} -> {len(got)} ficheros en {args.out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
