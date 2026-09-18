#!/usr/bin/env python3
"""Build web reproducible de Aethermere (Godot 4.7, sin threads).

Pasos: verifica assets generados, copia data/*.json a godot_project/data/,
genera export_presets.cfg (Web + thread_support=false para hosts estaticos
como GitHub Pages), exporta y limpia el staging.

Requiere: Godot 4.7 + templates (incl. web_nothreads_release).

Uso:
    python3 build_web.py --out web-dist
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT_PROJECT = os.path.join(ROOT, "godot_project")

PRESET = """\
[preset.0]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="{out}/index.html"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/ensure_cross_origin_isolation_headers=true
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
"""


def check_assets() -> list[str]:
    missing = []
    for rel, want in (("audio", ["music", "sfx"]), ("textures/ui", None),
                      ("models", None)):
        p = os.path.join(GODOT_PROJECT, rel)
        if not os.path.isdir(p):
            missing.append(rel + "/ (ejecuta setup_*.py)")
            continue
        if want and not all(os.path.isdir(os.path.join(p, w)) for w in want):
            missing.append(rel + "/ incompleto")
    for f in ("zones.json", "dialogues.json", "items.json", "monsters.json",
              "npcs.json", "quests.json", "skills.json"):
        if not os.path.isfile(os.path.join(ROOT, "data", f)):
            missing.append("data/" + f)
    return missing


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Build web de Aethermere")
    ap.add_argument("--out", default=os.path.join(ROOT, "web-dist"))
    ap.add_argument("--godot", default="godot")
    args = ap.parse_args(argv)

    problems = check_assets()
    for m in problems:
        print(f"AVISO falta: {m}")
    if any(m.startswith("data/") for m in problems):
        print("ERROR sin data/ no hay build", file=sys.stderr)
        return 1

    staged = os.path.join(GODOT_PROJECT, "data")
    preset = os.path.join(GODOT_PROJECT, "export_presets.cfg")
    out = os.path.abspath(args.out)
    try:
        if os.path.isdir(staged):
            shutil.rmtree(staged)
        shutil.copytree(os.path.join(ROOT, "data"), staged)
        with open(preset, "w", encoding="utf-8") as f:
            f.write(PRESET.format(out=out))
        os.makedirs(out, exist_ok=True)
        r = subprocess.run(
            [args.godot, "--headless", "--verbose", "--path", GODOT_PROJECT,
             "--export-release", "Web", os.path.join(out, "index.html")],
            capture_output=True, text=True, timeout=600)
        sys.stdout.write(r.stdout[-3000:])
        sys.stderr.write(r.stderr[-3000:])
        if r.returncode != 0:
            print("ERROR export fallo", file=sys.stderr)
            return 1
        if "nothreads" not in (r.stdout + r.stderr).lower():
            print("AVISO no se confirma template nothreads en el log")
        files = sorted(os.listdir(out))
        print("build:", files)
        need = [f for f in ("index.html", "index.js", "index.wasm", "index.pck")
                if f in files]
        if len(need) < 4:
            print(f"ERROR faltan piezas: {files}", file=sys.stderr)
            return 1
        total = sum(os.path.getsize(os.path.join(out, f)) for f in files)
        print(f"OK web-dist ({total / 1e6:.1f} MB)")
        return 0
    finally:
        if os.path.isdir(staged):
            shutil.rmtree(staged)
        if os.path.isfile(preset):
            os.remove(preset)


if __name__ == "__main__":
    sys.exit(main())
