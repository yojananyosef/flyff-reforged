## Why

Los 5 monstruos de Ironhold ya tienen modelo `.glb` con esqueleto, pero solo
usan `stand` (quieto) y `die` (al morir): vagan deslizando sin mover patas y
golpean por contacto sin animación de ataque. Los clips `walk` y `atk1/atk2`
ya existen dentro de los `.glb` (verificado en los 5), así que el coste es
solo cablearlos en `monster.gd`. Sin esto, el combate se siente muerto aunque
los números funcionen.

## What Changes

- `monster.gd`: bucle `walk`/`Walk` al vagar, clip `atk1`/`atk2` (una vez, sin
  bucle) al aplicar daño por contacto, y orientación del cuerpo hacia la
  dirección de marcha. `stand` queda como repliegue si no hay `walk`.
- Sin `atk` (Hollow Crow / loro: solo `Idle1`, `Stand`, `Walk`), el daño se
  aplica igual sin animación; sin `die`, se libera como hasta ahora.
- `main.gd` (sim): aserciones de que cada monstruo con modelo reproduce
  `walk` al vagar y `atk*` al golpear (o repliegue documentado en el loro).
- Sin cambios en el exportador: ya incluye todos los `.ani`.

## Capabilities

### New Capabilities

- `anim`: locomoción (`walk`) y ataque (`atk`) animados en monstruos con
  modelo, con repliegues definidos.

### Modified Capabilities

(none)

## Impact

- Solo `godot_project/scripts/monster.gd` + sim en `main.gd`; sin cambios en
  datos, exportador ni `.glb` (no se regeneran modelos).
- Sin modelo o sin clips, el comportamiento anterior se conserva (cápsula).
