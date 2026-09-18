## Why

Los `.glb` actuales son estáticos y el juego usa cápsulas: 6202 modelos
siguen sin pisar la escena. La investigación cerró las incógnitas duras
(`m1` = inversa de `m0`, `m2` = local en orden L·P, articulación =
`usebones[matIdx//3]`, `.ani` ≡ `.chr` en nombres). Toca el exportador
con esqueleto + animaciones y vestir a los 5 monstruos.

## What Changes

- `o3d_to_skinglb.py`: esqueleto de `.chr` (nodos, `transpose(m2)`),
  skin con IBMS `transpose(m1)`, mallas con joints/weights mapeados y
  animaciones de `.ani` (rotación/traslación por hueso, 30 fps asumidos).
- `monsters.json`: campo `model` (curaduría de 5 criaturas view-verificadas).
- `setup_models.py`: convierte los 5 modelos (+ sus `.ani`) a
  `godot_project/models/` (gitignorado, como audio/texturas).
- `monster.gd`: instancia el `.glb` (colisión cápsula igual), `stand` en
  loop y `die` al morir; sin modelo, cápsula como antes.

## Capabilities

### New Capabilities

- `skin`: exportador skinned+animado, setup de modelos e integración
  en monstruos.

### Modified Capabilities

- `game-data`: `monsters.json` gana `model` (compatible).
- `gameplay`: monstruos con modelo real y animaciones stand/die.

## Impact

- Sin setup de modelos, el juego sigue con cápsulas (repliegue).
- Movimiento/animación de caza (walk/attack) queda para la siguiente
  (solo stand/die cableados aquí).
