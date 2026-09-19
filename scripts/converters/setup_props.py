#!/usr/bin/env python3
"""Genera las estructuras del campamento de Ironhold como .glb texturados.

Piezas fijas: tiendas `Obj_EliunTent01/02` + muro `Obj_BeheBasicwall01`
(texturas `.dds` sueltas en `Model/Texture/`). Convierte a PNG (PIL,
RGBA) en un dir temporal y exporta vía `o3d_to_glb.py --tex-dir`.

Como el resto de generados, los .glb no se versionan (ver .gitignore).
La colocación vive en `data/zones.json ironhold.props`.

Uso:
    python3 setup_props.py --client /ruta/a/app --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "..", "parsers"))
from o3d_parser import parse_o3d  # noqa: E402

PROPS = [
    "Obj_EliunTent01.o3d",
    "Obj_EliunTent02.o3d",
    "Obj_BeheBasicwall01.o3d",
]

LOOSE_TEX_DIR = os.path.join("Model", "Texture")


def o3d_textures(o3d_path: str) -> set[str]:
    texs = set()
    for g in parse_o3d(o3d_path)["groups"][:1]:
        for ob in g["objects"]:
            for mt in ob["materials"]:
                t = str(mt.get("texture", ""))
                if t:
                    texs.add(t)
    return texs


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara props del campamento desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    args = ap.parse_args(argv)

    model_dir = os.path.join(args.client, "Model")
    want: dict[str, str] = {}
    for p in PROPS:
        o3d = os.path.join(model_dir, p)
        if not os.path.isfile(o3d):
            print(f"FALTA {p}", file=sys.stderr)
            return 1
        for t in o3d_textures(o3d):
            want.setdefault(os.path.splitext(t)[0].lower(), t)

    loose: dict[str, str] = {}
    tex_dir = os.path.join(args.client, LOOSE_TEX_DIR)
    if os.path.isdir(tex_dir):
        for fn in os.listdir(tex_dir):
            if fn.lower().endswith(".dds"):
                loose.setdefault(os.path.splitext(fn)[0].lower(),
                                 os.path.join(tex_dir, fn))

    with tempfile.TemporaryDirectory(prefix="props_tex_") as tmp:
        png_dir = os.path.join(tmp, "png")
        os.makedirs(png_dir)
        from PIL import Image  # type: ignore

        missing = []
        for base, exact in sorted(want.items()):
            src = loose.get(base)
            if src is None:
                missing.append(exact)
                continue
            png = os.path.join(
                png_dir, os.path.splitext(os.path.basename(exact))[0] + ".png")
            try:
                with Image.open(src) as im:
                    im.convert("RGBA").save(png)
            except OSError as e:
                print(f"DDS ilegible {exact}: {e}")
                missing.append(exact)
        if missing:
            print(f"aviso: {len(missing)} sin PNG {missing} (quedan en blanco)")
        print(f"PNG: {len(os.listdir(png_dir))}/{len(want)}")

        os.makedirs(args.out, exist_ok=True)
        fails = 0
        for p in PROPS:
            out = os.path.join(args.out, os.path.splitext(p)[0] + ".glb")
            r = subprocess.run(
                [sys.executable, os.path.join(_HERE, "o3d_to_glb.py"),
                 "--input", os.path.join(model_dir, p),
                 "--output", out, "--tex-dir", png_dir],
                capture_output=True, text=True)
            sys.stdout.write(r.stdout)
            if r.returncode != 0 or not os.path.isfile(out):
                print(f"ERROR {p}: {r.stderr.strip()[:200]}", file=sys.stderr)
                fails += 1
        if fails:
            return 1
    print(f"props: {len(PROPS)}/{len(PROPS)} en {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
