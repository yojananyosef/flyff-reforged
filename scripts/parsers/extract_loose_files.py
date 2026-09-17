#!/usr/bin/env python3
"""Extractor de archivos sueltos del cliente FlyFF v21 -> assets/.

Copia (sin modificar) los formatos reutilizables directamente:
    Music/*.ogg       -> assets/audio/music/
    Sound/*.wav       -> assets/audio/sfx/
    Theme/<lang>/*    -> assets/textures/ui/   (.tga/.bmp/.dds)
    Model/*.chr/.ani  -> assets/skeletons/, assets/animations/
    Model/*.o3d       -> assets/models_raw/    (pendientes de reverse engineering)
    World/**/*.lnd    -> assets/terrain_raw/
    Icon/*            -> assets/icons_raw/

No intenta descifrar .res (ver propuesta: se usan archivos sueltos + JSONs nuevos).

Uso:
    python3 extract_loose_files.py --client /ruta/a/app --out assets --lang English
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

TASKS: list[tuple[str, str, tuple[str, ...]]] = [
    ("Music", "audio/music", (".ogg",)),
    ("Sound", "audio/sfx", (".wav",)),
    ("Model", "skeletons", (".chr",)),
    ("Model", "animations", (".ani",)),
    ("Model", "models_raw", (".o3d",)),
    ("Icon", "icons_raw", (".tga", ".bmp", ".dds", ".inc", ".res")),
    ("SFX", "sfx_raw", (".sfx", ".tga", ".dds", ".res")),
]


def copy_ext(src_dir: Path, dst_dir: Path, exts: tuple[str, ...]) -> int:
    n = 0
    if not src_dir.is_dir():
        return 0
    dst_dir.mkdir(parents=True, exist_ok=True)
    for f in sorted(src_dir.iterdir()):
        if f.is_file() and f.suffix.lower() in exts:
            shutil.copy2(f, dst_dir / f.name)
            n += 1
    return n


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Extrae archivos sueltos del cliente FlyFF")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--out", required=True, help="Directorio assets de destino")
    ap.add_argument("--lang", default="English", help="Idioma de Theme (default: English)")
    ap.add_argument("--no-recursive-world", action="store_true")
    args = ap.parse_args(argv)

    client = Path(args.client)
    out = Path(args.out)
    if not client.is_dir():
        print(f"cliente no encontrado: {client}", file=sys.stderr)
        return 1

    total = 0
    report: list[tuple[str, int]] = []
    for src_rel, dst_rel, exts in TASKS:
        n = copy_ext(client / src_rel, out / dst_rel, exts)
        report.append((dst_rel, n))
        total += n

    # Texturas UI del idioma elegido
    n_ui = copy_ext(client / "Theme" / args.lang, out / "textures" / "ui",
                    (".tga", ".bmp", ".dds"))
    report.append(("textures/ui", n_ui))
    total += n_ui

    # Terrenos .lnd (recursivo por zonas)
    n_lnd = 0
    world = client / "World"
    if world.is_dir():
        dst = out / "terrain_raw"
        dst.mkdir(parents=True, exist_ok=True)
        for lnd in sorted(world.rglob("*.lnd")):
            rel = lnd.relative_to(world)
            target = dst / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(lnd, target)
            n_lnd += 1
    report.append(("terrain_raw", n_lnd))
    total += n_lnd

    for name, n in report:
        print(f"{name}: {n} archivos")
    print(f"TOTAL: {total} archivos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
