#!/usr/bin/env python3
"""Genera el avatar del jugador (vagabundo FlyFF) como .glb animado.

Combina `mvr_male.chr` + 5 piezas SKIN + 3 animaciones de cuerpo
completo vía o3d_to_skinglb.py (multi --o3d):

    piezas: Part_mVag01Upper/Hand/Foot + Part_maleHead06 + Part_maleHair06
    stand <- Mvr_male_GenFStand1-D | walk <- Mvr_male_GenRun
    atk1  <- Mvr_male_GenFAtk1-C

Nota: los sufijos -13/-14/-15 de marcha/carrera son posturas de
montura (torso plegado: hombro a la altura de la cadera); la familia
`GenFStand1/Running1-C` es casi estatica (piernas 0 grados).
`GenFStand1-D` es reposo relajado y erguido (hombro +0.39 sobre la
raiz), `GenRun` carrera erguida con zancada, `GenFAtk1-C` golpe en el
sitio — verificacion de varianza, pose absoluta y esqueleto en Godot
en el change aethermere-player-avatar.

Como monstruos y terreno, el .glb no se versiona (ver .gitignore).

Uso:
    python3 setup_player_model.py --client /ruta/a/app --out ../../godot_project/models
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))

PARTS = [
    "Part_mVag01Upper.o3d",
    "Part_mVag01Hand.o3d",
    "Part_mVag01Foot.o3d",
    "Part_maleHead06.o3d",
    "Part_maleHair06.o3d",
]

ANIS = {
    "stand.ani": "Mvr_male_GenFStand1-D.ani",
    "walk.ani": "Mvr_male_GenRun.ani",
    "atk1.ani": "Mvr_male_GenFAtk1-C.ani",
}

CHR = "mvr_male.chr"
OUTPUT = "PlayerMvr.glb"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara el avatar del jugador desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--out", required=True, help="Destino (godot_project/models)")
    ap.add_argument("--tex-dir", default=None,
                    help="Dir con <textura>.png para embeber (ver setup_model_textures.py)")
    args = ap.parse_args(argv)

    model_dir = os.path.join(args.client, "Model")
    missing = []
    chr_f = os.path.join(model_dir, CHR)
    if not os.path.isfile(chr_f):
        missing.append(f"falta {CHR}")
    for p in PARTS:
        if not os.path.isfile(os.path.join(model_dir, p)):
            missing.append(f"falta pieza {p}")
    for target, src in ANIS.items():
        if not os.path.isfile(os.path.join(model_dir, src)):
            missing.append(f"falta animación {src} (->{target})")
    if missing:
        for x in missing:
            print(f"FALTA {x}", file=sys.stderr)
        return 1

    os.makedirs(args.out, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="player_ani_") as tmp:
        for target, src in ANIS.items():
            shutil.copy(os.path.join(model_dir, src), os.path.join(tmp, target))
        cmd = [sys.executable, os.path.join(_HERE, "o3d_to_skinglb.py")]
        for p in PARTS:
            cmd += ["--o3d", os.path.join(model_dir, p)]
        cmd += ["--chr", chr_f, "--anis", os.path.join(tmp, "*.ani"),
                "--output", os.path.join(args.out, OUTPUT)]
        if args.tex_dir:
            cmd += ["--tex-dir", args.tex_dir]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.isfile(os.path.join(args.out, OUTPUT)):
            print(f"ERROR conversor: {r.stderr.strip()[:300]}", file=sys.stderr)
            return 1
        print(r.stdout.strip())
    print(f"jugador: {OUTPUT} en {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
