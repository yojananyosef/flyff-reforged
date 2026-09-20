## Why

Fenmarch promete niveles 4–8 pero solo tiene monstruos 4–6 y la cadena 201–205 termina sin finale; sin boss ni curva completa no hay arco de progresión que justifique el viaje desde Ironhold.

## What Changes

- `data/monsters.json`: `mon_010`–`mon_012` (Fenmarch, niveles 7–8 + boss, modelos reutilizados, stats de curva 4–8).
- `data/quests.json`: cadena se extiende a 206 (boss final, `requires quest_205`, giver `npc_003`); `quest_205` pasa a desbloquear 206.
- `data/zones.json`: `fenmarch.monsters` incluye 010–012; `npcs.json`: `npc_003` ofrece 206.
- `data/dialogues.json`: `dlg_sella_intro` con nodo de boss (aviso del alpha verdadero).
- `godot_project/scripts/main.gd`: SIM-QUEST cubre 201–206 + boss, spawn y conteo multizona intactos.
- Fuera de alcance: tercera zona, segunda clase, mapa del mundo, loot épico/sets.

## Capabilities

### New Capabilities

- `fenmarch-boss`: Boss de Fenmarch jugable con curva 4–8 completa y quest 206 de cierre.

### Modified Capabilities

- `second-zone`: la cadena de Fenmarch avanza hasta la 206 (antes 205).

## Impact

- `data/` + `main.gd` (sim). Los 179 checks actuales SHALL seguir pasando; `validate --strict` OK.
