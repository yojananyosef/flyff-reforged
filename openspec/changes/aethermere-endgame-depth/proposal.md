## Why

Tras la 206 el juego se acaba: Sella no tiene nada más que decir, Pell es el único mercader (en Ironhold), subir de nivel solo cura y el equipo Alpha es invisible. Cuatro huecos pequeños que juntos deciden si Fenmarch es un final o un lugar para quedarse.

## What Changes

- `data/quests.json`: `quest_207`–`quest_209` (contratos repetibles de Sella, `requires quest_206`, oro/EXP sin unlocks); `quest_manager.gd`: flag `repeatable` (al completar no entra en `done` y vuelve a estar disponible; el viaje reconstruye la zona y refresca las presas).
- `data/npcs.json` + `dialogues.json` + `zones.json`: `npc_004` mercader en Fenmarch (modelo reutilizado, sin quests, con diálogo de mercader y Comerciar).
- `godot_project/scripts/player.gd`: cada nivel SHALL dar +12 `max_hp` y +4 `max_mp` (además de curar); ataque/defensa base intactos (el equipo sigue mandando).
- `godot_project/scripts/player.gd`: props procedurales de equipo (`GearBlade` + hombreras) hijos de `Model`, color/tamaño por tier; al desequipar se ocultan.
- `godot_project/scripts/main.gd`: SIM-QUEST cubre repetibles, mercader, crecimiento y visual.
- Fuera de alcance: tercera zona, minimapa, sets con bonus, armas `.glb` nuevas, re balance del boss (los números 218 SHALL seguir pasando).

## Capabilities

### New Capabilities

- `bounties`: Contratos repetibles de Sella tras la 206.
- `fenmarch-merchant`: Mercader propio en Fenmarch.
- `level-growth`: Crecimiento de HP/MP por nivel.
- `gear-visuals`: Equipo visible por tier (props procedurales).

### Modified Capabilities

(none)

## Impact

- `data/` + `quest_manager.gd` + `player.gd` + `main.gd` (sim). Sin migración de saves (los viejos conservan su `max_hp`; el crecimiento aplica en nuevos niveles). `validate --strict` OK.
