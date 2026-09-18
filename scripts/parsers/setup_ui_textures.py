#!/usr/bin/env python3
"""Copia las 6 texturas UI curadas de Aethermere desde el cliente.

Godot importa .tga nativo: no hay conversion. Como el audio, los
binarios no se versionan (ver .gitignore); sin ellos la UI usa
fondos planos sin romperse.

Curaduria (ver proposal aethermere-uitex):
    WndMessagebox.tga  fondo de dialogo, tienda e inventario (256x144)
    BarRed.tga         icono HP (orbe 12x14)
    BarGreen.tga       icono EXP (orbe 12x14)
    BarSky.tga         icono MP (orbe 12x14)
    WndBar01.tga       tira decorativa (278x14, reserva)

(WndDialog.tga se descarta: trae marcos horneados que chocan con el contenido.)

Uso:
    python3 setup_ui_textures.py --client /ruta/a/app --out ../../godot_project/textures/ui
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

FILES = [
    "WndMessagebox.tga",
    "BarRed.tga",
    "BarGreen.tga",
    "BarSky.tga",
    "WndBar01.tga",
]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara texturas UI de Aethermere")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--out", required=True, help="Destino (godot_project/textures/ui)")
    ap.add_argument("--lang", default="English")
    args = ap.parse_args(argv)

    src = Path(args.client) / "Theme" / args.lang
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    ok, missing = 0, []
    for fname in FILES:
        f = src / fname
        if f.is_file():
            shutil.copy2(f, out / fname)
            ok += 1
        else:
            missing.append(fname)
    print(f"texturas ui: {ok}/{len(FILES)} archivos en {out}")
    for m in missing:
        print(f"FALTA {m}", file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
