#!/usr/bin/env python3
"""Copia los 16 archivos de audio usados por Aethermere desde el cliente.

Los binarios no se versionan (ver .gitignore): cada desarrollador ejecuta
esto una vez tras extraer el cliente. Sin estos archivos el juego arranca
en silencio con un aviso.

Uso:
    python3 setup_audio.py --client /ruta/a/app --out ../../godot_project/audio
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

# nombre logico -> (subdir cliente, archivo)
MUSIC: dict[str, str] = {
    "zone_ironhold": "BgmBa3Saintmorning.ogg",
    "combat": "BgmBaCrisis.ogg",
    "sting_quest": "BgmNPCAccomplish.ogg",
    "sting_death": "BgmInDeath.ogg",
}

SFX: dict[str, str] = {
    "swing": "NpcComSwing01.wav",
    "hit": "Item1WpnAtk.wav",
    "monster_hurt": "NpcAibattDmg1.wav",
    "monster_die": "NpcAibattDie1.wav",
    "player_hurt": "PcDmgSwdC.wav",
    "level_up": "PcLevelup.wav",
    "quest_accept": "ActionRegister.wav",
    "ui_click": "InfClick.wav",
    "ui_open": "InfOpen.wav",
    "ui_close": "InfClose.wav",
    "pickup": "InfGroundPickup.wav",
    "reward": "ItemDropDing.wav",
}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Prepara audio de Aethermere desde el cliente")
    ap.add_argument("--client", required=True, help="Directorio 'app' del cliente extraido")
    ap.add_argument("--out", required=True, help="Destino (godot_project/audio)")
    args = ap.parse_args(argv)

    client = Path(args.client)
    out = Path(args.out)
    jobs = [("Music", "music", MUSIC), ("Sound", "sfx", SFX)]
    ok, missing = 0, []
    for sub, dest, mapping in jobs:
        (out / dest).mkdir(parents=True, exist_ok=True)
        for logical, fname in mapping.items():
            src = client / sub / fname
            if src.is_file():
                shutil.copy2(src, out / dest / fname)
                ok += 1
            else:
                missing.append(f"{sub}/{fname} (para '{logical}')")
    total = len(MUSIC) + len(SFX)
    print(f"audio: {ok}/{total} archivos en {out}")
    for m in missing:
        print(f"FALTA {m}", file=sys.stderr)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
