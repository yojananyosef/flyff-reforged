#!/usr/bin/env python3
"""Validador de datos de Aethermere (data/*.json).

Comprueba:
  - JSON valido en los 7 archivos esperados.
  - IDs unicos dentro de cada archivo.
  - Referencias cruzadas: monster.zone -> zones, monster.drops -> items,
    npc.zone -> zones, npc.dialogue_id -> dialogues, npc.quests_available -> quests,
    quest.giver -> npcs, quest.target.monster_id -> monsters,
    quest.rewards.items -> items, quest.requires/unlocks -> quests,
    dialogue.npc_id -> npcs, dialogue options next -> node_ids del mismo dialogo,
    zone.npcs -> npcs, zone.monsters -> monsters, zone.original_asset_dir presente.
  - Contenido minimo: zona ironhold, mision 101 desbloquea 102, dialogo >= 2 nodos.

Uso:
    python3 validate_data.py [--data-dir data]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

EXPECTED = ["items.json", "monsters.json", "skills.json", "npcs.json",
            "quests.json", "dialogues.json", "zones.json"]


def load(data_dir: Path) -> tuple[dict, list[str]]:
    errors: list[str] = []
    data: dict = {}
    for name in EXPECTED:
        p = data_dir / name
        if not p.is_file():
            errors.append(f"falta {name}")
            continue
        try:
            data[name] = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"{name}: JSON invalido ({e})")
    return data, errors


def ids(rows: list, key: str = "id") -> list:
    return [r.get(key) for r in rows if isinstance(r, dict)]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Valida data/*.json de Aethermere")
    ap.add_argument("--data-dir", default="data")
    args = ap.parse_args(argv)
    data_dir = Path(args.data_dir)
    data, errors = load(data_dir)

    if errors:
        for e in errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1

    items = {r["id"]: r for r in data["items.json"]}
    monsters = {r["id"]: r for r in data["monsters.json"]}
    skills = {r["id"]: r for r in data["skills.json"]}
    npcs = {r["id"]: r for r in data["npcs.json"]}
    quests = {r["id"]: r for r in data["quests.json"]}
    dialogues = {r["id"]: r for r in data["dialogues.json"]}
    zones = {r["id"]: r for r in data["zones.json"]}

    # IDs unicos
    for name, rows in data.items():
        seen, dupes = set(), set()
        for r in rows:
            i = r.get("id")
            if i in seen:
                dupes.add(i)
            seen.add(i)
        if dupes:
            errors.append(f"{name}: IDs duplicados {sorted(dupes)}")

    def ref(cond: bool, msg: str) -> None:
        if not cond:
            errors.append(msg)

    for m in monsters.values():
        ref(m.get("zone") in zones, f"monsters {m.get('id')}: zona inexistente {m.get('zone')!r}")
        for d in m.get("drops", []):
            ref(d in items, f"monsters {m.get('id')}: drop inexistente {d!r}")

    for n in npcs.values():
        ref(n.get("zone") in zones, f"npcs {n.get('id')}: zona inexistente {n.get('zone')!r}")
        ref(n.get("dialogue_id") in dialogues,
            f"npcs {n.get('id')}: dialogo inexistente {n.get('dialogue_id')!r}")
        for q in n.get("quests_available", []):
            ref(q in quests, f"npcs {n.get('id')}: quest inexistente {q!r}")

    for q in quests.values():
        ref(q.get("giver") in npcs, f"quests {q.get('id')}: giver inexistente {q.get('giver')!r}")
        tgt = q.get("target", {}) or {}
        if tgt.get("type") == "kill":
            ref(tgt.get("monster_id") in monsters,
                f"quests {q.get('id')}: monstruo inexistente {tgt.get('monster_id')!r}")
        for it in (q.get("rewards", {}) or {}).get("items", []):
            ref(it in items, f"quests {q.get('id')}: reward inexistente {it!r}")
        for link in ("requires", "unlocks"):
            v = q.get(link)
            if v is not None:
                ref(v in quests, f"quests {q.get('id')}: {link} inexistente {v!r}")

    for d in dialogues.values():
        ref(d.get("npc_id") in npcs,
            f"dialogues {d.get('id')}: npc inexistente {d.get('npc_id')!r}")
        nodes = {n.get("node_id") for n in d.get("nodes", [])}
        ref(len(nodes) >= 2, f"dialogues {d.get('id')}: se exigen >= 2 nodos")
        for n in d.get("nodes", []):
            for o in n.get("options", []):
                ref(o.get("next") in nodes,
                    f"dialogues {d.get('id')}: next inexistente {o.get('next')!r}")

    for z in zones.values():
        ref(bool(z.get("original_asset_dir")),
            f"zones {z.get('id')}: falta original_asset_dir")
        ref(bool(z.get("display_name")),
            f"zones {z.get('id')}: falta display_name")
        for n in z.get("npcs", []):
            ref(n in npcs, f"zones {z.get('id')}: npc inexistente {n!r}")
        for m in z.get("monsters", []):
            ref(m in monsters, f"zones {z.get('id')}: monstruo inexistente {m!r}")

    # Contenido minimo Aethermere
    ref("ironhold" in zones, "falta zona 'ironhold'")
    ref("quest_101" in quests and quests["quest_101"].get("unlocks") == "quest_102",
        "quest_101 debe desbloquear quest_102")
    ref(quests.get("quest_102", {}).get("requires") == "quest_101",
        "quest_102 debe requerir quest_101")
    ref(len(items) >= 10, f"se exigen >= 10 items (hay {len(items)})")
    ref(len(monsters) >= 5, f"se exigen >= 5 monstruos (hay {len(monsters)})")
    ref(len(skills) >= 3, f"se exigen >= 3 habilidades (hay {len(skills)})")

    if errors:
        for e in errors:
            print(f"ERROR {e}", file=sys.stderr)
        return 1
    print(f"OK data/ valido: {len(items)} items, {len(monsters)} monstruos, "
          f"{len(npcs)} npcs, {len(quests)} quests, {len(dialogues)} dialogos, "
          f"{len(skills)} skills, {len(zones)} zonas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
