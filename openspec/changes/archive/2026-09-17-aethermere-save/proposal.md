## Why

Todo el progreso vive en RAM: cerrar el juego borra nivel, oro, equipo
y las 10 misiones. Con la cadena completa, esto convierte el MVP en una
demo de una sentada. El guardado es el mayor hueco funcional restante y
no depende de assets ni de red.

## What Changes

- Autoload `save_manager`: `save_game()`, `load_game() -> bool`,
  `new_game()`, archivo `user://aethermere_save.json` (JSON legible).
- Guarda: zona, posición, nivel/EXP/HP/MP, oro, inventario, equipo y
  misiones (activas con conteo + completadas).
- F5 guardado manual, F8 nueva partida (borra + recarga escena),
  auto-guardado al completar misión, auto-carga al arrancar si existe.
- Simulación: guarda, adultera estado, carga y verifica restauración.

## Capabilities

### New Capabilities

- `save`: persistencia local del progreso.

### Modified Capabilities

- `gameplay`: `quest_manager` auto-guarda al completar; la simulación
  cubre guardar/cargar.

## Impact

- Un archivo por usuario fuera del repo; formato versionado (`version: 1`)
  para migraciones futuras.
- Sin cambios en `data/` ni en economía.
