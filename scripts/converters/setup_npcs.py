#!/usr/bin/env python3
"""Genera los cuerpos de los NPC de Aethermere como .glb texturados.

Lee `data/npcs.json` (campo `model`) y por cada uno combina
`<model>.o3d + <model>.chr + <model>_*.ani` via o3d_to_skinglb.py, con
texturas `.dds` sueltas de `Model/Texture/` pasadas a PNG (PIL, RGBA).

Como el resto de generados, los .glb no se versionan (ver .gitignore).

Uso:
    python3 setup_npcs.py --client /ruta/a/app --data ../../data --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "..", "parsers"))
from o3d_parser import parse_o3d  # noqa: E402

LOOSE_TEX_DIR = os.path.join("Model", "Texture")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara NPC de Aethermere desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--data", required=True, help="Directorio data/ con npcs.json")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    args = ap.parse_args(argv)

    with open(os.path.join(args.data, "npcs.json"), encoding="utf-8") as f:
        npcs = json.load(f)

    loose: dict[str, str] = {}
    tex_dir = os.path.join(args.client, LOOSE_TEX_DIR)
    if os.path.isdir(tex_dir):
        for fn in os.listdir(tex_dir):
            if fn.lower().endswith(".dds"):
                loose.setdefault(os.path.splitext(fn)[0].lower(),
                                 os.path.join(tex_dir, fn))

    with tempfile.TemporaryDirectory(prefix="npc_tex_") as tmp:
        png_dir = os.path.join(tmp, "png")
        os.makedirs(png_dir)
        from PIL import Image  # type: ignore

        os.makedirs(args.out, exist_ok=True)
        ok, missing = 0, []
        for n in npcs:
            model = str(n.get("model", ""))
            if not model:
                continue
            o3d = os.path.join(args.client, "Model", model + ".o3d")
            chr_f = os.path.join(args.client, "Model", model + ".chr")
            anis = sorted(glob.glob(os.path.join(args.client, "Model", model + "_*.ani")))
            if not (os.path.isfile(o3d) and os.path.isfile(chr_f) and anis):
                missing.append(f"{n.get('id')}: falta .o3d/.chr/.ani para '{model}'")
                continue
            want = set()
            for g in parse_o3d(o3d)["groups"][:1]:
                for ob in g["objects"]:
                    for mt in ob["materials"]:
                        t = str(mt.get("texture", ""))
                        if t:
                            want.add(t)
            for t in sorted(want):
                src = loose.get(os.path.splitext(t)[0].lower())
                if src is None:
                    print(f"aviso: sin DDS para {t} (pieza en blanco)")
                    continue
                png = os.path.join(png_dir, os.path.splitext(t)[0] + ".png")
                try:
                    with Image.open(src) as im:
                        im.convert("RGBA").save(png)
                except OSError as e:
                    print(f"DDS ilegible {t}: {e}")
            out = os.path.join(args.out, model + ".glb")
            r = subprocess.run(
                [sys.executable, os.path.join(_HERE, "o3d_to_skinglb.py"),
                 "--o3d", o3d, "--chr", chr_f,
                 "--anis", os.path.join(args.client, "Model", model + "_*.ani"),
                 "--output", out, "--tex-dir", png_dir],
                capture_output=True, text=True)
            sys.stdout.write(r.stdout)
            if r.returncode != 0 or not os.path.isfile(out):
                missing.append(f"{n.get('id')}: conversor fallo ({r.stderr.strip()[:200]})")
                continue
            ok += 1
            print(f"OK {model} ({len(anis)} anis)")
    print(f"npcs: {ok} en {args.out}")
    for x in missing:
        print(f"FALTA {x}", file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
