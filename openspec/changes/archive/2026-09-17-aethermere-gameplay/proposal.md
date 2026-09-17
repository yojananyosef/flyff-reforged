## Why

La base `aethermere-base` (archivada) deja un muñeco que camina por una
zona vacía: hay datos de misiones, diálogos, monstruos e items, pero nada
los usa. Esta propuesta añade el primer slice jugable: hablar con la
Anciana Maren, aceptar la misión 101, cazar liebres cinéreas placeholder,
completar la 101, desbloquear la 102 y ver drops en el inventario.

## What Changes

- Autoload `quest_manager`: aceptar, progreso de muertes, completar,
  recompensas y desbloqueo 101 → 102.
- Interacción con NPC (tecla E) + panel de diálogo que navega los nodos
  de `dialogues.json`, con botón de aceptar misión.
- Combate cuerpo a cuerpo (clic): placeholders de monstruos generados
  desde `monsters.json` (cápsulas con IA errante mínima, HP, daño por
  contacto, muerte con EXP + drops).
- Inventario en el jugador + panel (tecla I) con items iniciales y drops.
- Hilo de verificación headless (`--sim-quest`) que simula el flujo
  completo de misión y reporta PASS/FAIL.

## Capabilities

### New Capabilities

- `gameplay`: diálogo interactivo, misiones, combate placeholder e inventario.

### Modified Capabilities

- `godot-base`: la escena principal gana NPC, spawns de monstruos, paneles
  de diálogo/inventario y gancho de simulación headless.

## Impact

- Solo `godot_project/` + un spec nuevo; `data/` no cambia (ya validado).
- Sin red ni multijugador; placeholders visuales hasta la Fase 5.
