## Why

Ironhold está completo pero es un callejón sin salida: una sola zona,
sin progresión geográfica. Todo el pipeline es data-driven (terreno
por `.lnd`, monstruos/NPC/props/quests por JSON), así que una segunda
zona es "más de lo mismo" con riesgo bajo y convierte la demo en un
juego con progresión: altiplano interior (tiles 15–16/05–06, relieve
real sin vacío), 4 monstruos, cadena 201–205 y portal de viaje.

## What Changes

- `scripts/converters/setup_terrain.py`: flags `--tiles`, `--center`
  y `--name` (defecto: Ironhold actual) → `terrain_fenmarch.*`.
- `data/zones.json`: zona `fenmarch` (spawn, props, `travel` a
  Ironhold y viceversa); `npcs.json`: `x,z` por NPC + `npc_003`
  (Warden Sella Rook, `Mvr_NpcRaundas`).
- `data/monsters.json`: `mon_006`–`mon_009` (Fenmarch, modelos
  reutilizados, niveles 4–7); `data/quests.json`: cadena 201–205
  (`requires quest_110` para la 201, giver `npc_003`);
  `data/dialogues.json`: `dlg_sella_intro`.
- `godot_project/scripts/main.gd`: terreno/props/NPC por zona actual
  (slotes `$NPC`/`$NPC2` posicionados desde datos), portales de viaje
  (`E` cerca: fija zona, guarda y recarga la escena).
- Fuera de alcance: tercera zona, monturas, mapa del mundo, viaje
  con cooldown/costo.

## Capabilities

### New Capabilities

- `second-zone`: Fenmarch jugable con cadena propia y viaje bidireccional.

### Modified Capabilities

(none)

## Impact

- `scripts/` + datos + `main.gd` (+ `.glb` no versionados). El
  `SIM-QUEST` crece con viaje ida/vuelta y cadena 201; los 160 checks
  actuales SHALL seguir pasando.
