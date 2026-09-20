## Why

Fenmarch exige niveles 4–8 y un boss de 320 HP, pero el jugador llega con equipo de nivel 1 (ataque 8, defensa 3): el básico rasca al boss (1 por golpe) y el boss mata en ~5 golpes. Sin tier de equipo la curva y el boss no son jugables.

## What Changes

- `data/items.json`: `item_011`–`item_014` (2 armas + 2 armaduras tier Fenmarch, `level_required` 4/4/7/7, precios 90/80/220/200).
- `data/quests.json`: 202 premia espada Ridge, 204 premia abrigo Ridge, 206 premia espada Alpha (además de lo actual); resto de la cadena intacta.
- `godot_project/scripts/hud.gd`: `SHOP_STOCK` incluye los 4 nuevos (comprables con requisito de nivel).
- `godot_project/scripts/main.gd`: SIM-QUEST cubre compra/equipo y asserts de balance (TTK y supervivencia del boss).
- Fuera de alcance: mercader nuevo en Fenmarch (se compra a Pell viajando), crecimiento de stats por nivel, loot épico/sets, tercera zona.

## Capabilities

### New Capabilities

- `fenmarch-gear`: Tier de equipo 4–8 comprable y de recompensa que hace jugables la curva y el boss.

### Modified Capabilities

- `shop`: el stock incluye el tier Fenmarch con requisito de nivel.
- `fenmarch-boss`: la 206 premia equipo Alpha y el boss es derrotable con build completa + consumibles.

## Impact

- `data/` + `hud.gd` (stock) + `main.gd` (sim). Los 198 checks actuales SHALL seguir pasando; `validate --strict` OK.
