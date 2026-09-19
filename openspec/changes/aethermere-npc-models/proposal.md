## Why

Maren y Pell siguen siendo cápsulas verde/naranja y desentonan junto a
las tiendas nuevas. El cliente trae NPC humanoides con `.chr` e idle
(`Mvr_NpcSebrance` para el anciano, `mvr_NpcBato` para el explorador)
más sus `.dds` sueltos. Toca darles cuerpo con la misma técnica de
`skin-texture`, con repliegue a cápsula.

## What Changes

- `data/npcs.json`: campo `model` por NPC.
- `scripts/converters/setup_npcs.py` (nuevo, espejo de
  `setup_models.py`): genera `<modelo>.glb` texturados vía
  `o3d_to_skinglb.py --tex-dir` (no versionados).
- `godot_project/scripts/main.gd`: `npc_setup()` monta el `.glb` si
  existe (oculta la cápsula, idle/stand en bucle, encara al spawn);
  si no, cápsulas actuales.
- Fuera de alcance: animaciones de diálogo/gestos, más NPC.

## Capabilities

### New Capabilities

- `npc-models`: NPC con cuerpo FlyFF animado (idle) y repliegue.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/` + `data/npcs.json` + `main.gd` (+ `.glb` no
  versionados). Sin cambios en diálogos, tienda ni misiones.
