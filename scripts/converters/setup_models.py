#!/usr/bin/env python3
"""Convierte los modelos de monstruos de Aethermere a .glb animados.

Lee `data/monsters.json` (campo `model`) y por cada uno combina
`<model>.o3d + <model>.chr + <model>_*.ani` via o3d_to_skinglb.py.
Como audio/texturas, los .glb no se versionan (ver .gitignore).

Uso:
    python3 setup_models.py --client /ruta/a/app --data ../../data --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import subprocess
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara modelos de Aethermere desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--data", required=True, help="Directorio data/ con monsters.json")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    ap.add_argument("--tex-dir", default=None,
                    help="Dir con <textura>.png para embeber (ver setup_model_textures.py)")
    args = ap.parse_args(argv)

    with open(os.path.join(args.data, "monsters.json"), encoding="utf-8") as f:
        monsters = json.load(f)
    os.makedirs(args.out, exist_ok=True)
    ok, missing = 0, []
    for m in monsters:
        model = m.get("model", "")
        o3d = os.path.join(args.client, "Model", model + ".o3d")
        chr_f = os.path.join(args.client, "Model", model + ".chr")
        anis = sorted(glob.glob(os.path.join(args.client, "Model", model + "_*.ani")))
        if not (os.path.isfile(o3d) and os.path.isfile(chr_f) and anis):
            missing.append(f"{m.get('id')}: falta .o3d/.chr/.ani para '{model}'")
            continue
        out = os.path.join(args.out, model + ".glb")
        r = subprocess.run(
            [sys.executable, os.path.join(_HERE, "o3d_to_skinglb.py"),
             "--o3d", o3d, "--chr", chr_f,
             "--anis", os.path.join(args.client, "Model", model + "_*.ani"),
             "--output", out] + (["--tex-dir", args.tex_dir]
                                 if args.tex_dir else []),
            capture_output=True, text=True)
        if r.returncode != 0 or not os.path.isfile(out):
            missing.append(f"{m.get('id')}: conversor fallo ({r.stderr.strip()[:200]})")
            continue
        ok += 1
        print(f"OK {model} ({len(anis)} anis)")
    print(f"modelos: {ok}/{len(monsters)} en {args.out}")
    for x in missing:
        print(f"FALTA {x}", file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
