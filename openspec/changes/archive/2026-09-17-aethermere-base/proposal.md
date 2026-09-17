## Why

Necesitamos una base jugable mínima que demuestre el pipeline completo:
leer assets del cliente FlyFF v21, convertirlos a formatos estándar y usarlos
en un proyecto Godot 4 con lore nuevo (Aethermere). Sin esta base no se puede
avanzar paso a paso en gameplay, contenido ni integración de assets.

## What Changes

- Estructura base del proyecto (`scripts/`, `data/`, `assets/`, `godot_project/`, `docs/`) — ya creada en este commit.
- Parser `.chr` (esqueletos) en Python con salida JSON.
- Parser `.ani` (animaciones) en Python con salida JSON.
- Extractor de archivos sueltos del cliente (audio, texturas UI, modelos) sin descifrar `.res`.
- Esquemas JSON de datos nuevos: `items`, `monsters`, `npcs`, `quests`, `dialogues`, `skills`, `zones`.
- Proyecto Godot 4 mínimo: escena principal, jugador 3ª persona, HUD básico.
- Mapeo inicial de zonas FlyFF → Aethermere (ej. `WdMadrigal` → `Ironhold`).
- Investigación documentada del formato `.o3d` (header XOR `0xCD` resuelto, cuerpo pendiente).

## Capabilities

### New Capabilities

- `flyff-parsers`: parsers Python para formatos del cliente FlyFF (`.chr`, `.ani`, extractor de sueltos, investigación `.o3d`).
- `game-data`: esquemas y archivos JSON de datos del juego nuevo (items, monsters, npcs, quests, dialogues, skills, zones).
- `godot-base`: proyecto Godot 4 mínimo jugable (movimiento 3ª persona, cámara orbital, HUD HP/MP/EXP).

### Modified Capabilities

- (ninguna — proyecto nuevo, sin specs existentes)

## Impact

- Afecta solo a este repo nuevo (`flyff-reforged`); sin dependencias externas salvo Python 3.10+, Godot 4.x y OpenSpec CLI.
- Los assets originales FlyFF no se versionan (ver `.gitignore`); cada desarrollador los extrae de su cliente.
- El repo de referencia `NukeZero/Flyff-v21` se usa solo como documentación de estructuras de datos, no se copia código.
