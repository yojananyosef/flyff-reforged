#!/usr/bin/env python3
"""Viste al jugador y los monstruos con sus texturas .dds del cliente.

Resuelve cada textura referenciada por los .o3d (sueltos en
`Model/Texture/` o en `Model/Texture/part_mTex.res`), las pasa a PNG
(PIL, RGBA) en un dir temporal y regenera los 6 .glb vía
`setup_models.py` + `setup_player_model.py` con `--tex-dir`.

Como el resto de generados, los .glb no se versionan (ver .gitignore).

Uso:
    python3 setup_model_textures.py --client /ruta/a/app --data ../../data --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "..", "parsers"))
from o3d_parser import parse_o3d  # noqa: E402
from res_parser import list_res, extract_res  # noqa: E402

PLAYER_PARTS = [
    "Part_mVag01Upper.o3d",
    "Part_mVag01Hand.o3d",
    "Part_mVag01Foot.o3d",
    "Part_maleHead06.o3d",
    "Part_maleHair06.o3d",
]

PART_RES = os.path.join("Model", "Texture", "part_mTex.res")
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
    ap = argparse.ArgumentParser(description="Prepara texturas de personajes desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--data", required=True, help="Directorio data/ con monsters.json")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    args = ap.parse_args(argv)

    model_dir = os.path.join(args.client, "Model")
    with open(os.path.join(args.data, "monsters.json"), encoding="utf-8") as f:
        monsters = json.load(f)

    # Texturas requeridas por los .o3d (jugador + monstruos).
    want: dict[str, str] = {}  # base en minusculas -> nombre exacto del material
    o3ds = [os.path.join(model_dir, p) for p in PLAYER_PARTS]
    o3ds += [os.path.join(model_dir, str(m.get("model", "")) + ".o3d")
             for m in monsters if str(m.get("model", ""))]
    for o3d in o3ds:
        if not os.path.isfile(o3d):
            print(f"FALTA {o3d}", file=sys.stderr)
            return 1
        for t in o3d_textures(o3d):
            want.setdefault(os.path.splitext(t)[0].lower(), t)
    print(f"texturas requeridas: {len(want)}")

    # Índice de sueltos (Model/Texture/) insensible a mayúsculas.
    loose: dict[str, str] = {}
    tex_dir = os.path.join(args.client, LOOSE_TEX_DIR)
    if os.path.isdir(tex_dir):
        for fn in os.listdir(tex_dir):
            if fn.lower().endswith(".dds"):
                loose.setdefault(os.path.splitext(fn)[0].lower(),
                                 os.path.join(tex_dir, fn))

    # Entradas del pack de piezas (part_mTex.res).
    pack = os.path.join(args.client, PART_RES)
    pack_names: dict[str, str] = {}
    if os.path.isfile(pack):
        _, entries = list_res(pack)
        for e in entries:
            pack_names.setdefault(os.path.splitext(e["name"])[0].lower(),
                                  e["name"])

    with tempfile.TemporaryDirectory(prefix="model_tex_") as tmp:
        png_dir = os.path.join(tmp, "png")
        os.makedirs(png_dir)
        from PIL import Image  # type: ignore

        missing = []
        for base, exact in sorted(want.items()):
            src = loose.get(base)
            if src is None and base in pack_names:
                got = extract_res(pack, tmp, {pack_names[base]})
                if got:
                    src = os.path.join(tmp, got[0])
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

        for cmd in (
                [sys.executable, os.path.join(_HERE, "setup_models.py"),
                 "--client", args.client, "--data", args.data,
                 "--out", args.out, "--tex-dir", png_dir],
                [sys.executable, os.path.join(_HERE, "setup_player_model.py"),
                 "--client", args.client,
                 "--out", args.out, "--tex-dir", png_dir]):
            r = subprocess.run(cmd, capture_output=True, text=True)
            sys.stdout.write(r.stdout)
            if r.returncode != 0 or "FALTA" in r.stderr:
                print(f"ERROR: {' '.join(cmd[:2])}: {r.stderr.strip()[:300]}",
                      file=sys.stderr)
                return 1
    print("modelos con textura listos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
