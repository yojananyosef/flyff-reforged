## Why

Dos frenos de combate detectados jugando:

1. La IA deambula al azar y nada la interrumpe: un monstruo que te está
   golpeando sigue su paseo aleatorio y se aleja en mitad del combate. El
   deambular SHALL interrumpirse al entrar en combate.
2. No hay forma de fijar objetivo: el clic golpea "al más cercano en rango"
   y falla en silencio fuera de rango, así que no se puede elegir a qué
   monstruo pegar ni comprobar daño/animaciones sobre uno concreto.

## What Changes

- `monster.gd`: agro por proximidad (8 m) y por daño recibido; persecución
  a 2.8 m/s mirando al jugador; el deambular se suspende en combate y se
  retoma al perder agro (leash 14 m). El daño por contacto y su cooldown
  no cambian.
- `player.gd`: clic con ratón capturado fija objetivo por rayo desde el
  centro de pantalla (punto de mira) hasta 100 m; si está en rango ataca
  además; si no, solo lo fija y avisa. Básico y Ember priorizan el objetivo
  válido en rango; sin objetivo, comportamiento anterior (más cercano).
- `hud.gd`: punto de mira central + etiqueta de objetivo (nombre y HP).
- `main.tscn`: pista de controles actualizada ("Clic fijar/atacar").
- Sim: aserciones de agro (proximidad, persecución, agro por daño, leash) y
  de target (daño al objetivo aunque haya otro más cerca, fueras de rango,
  limpieza al morir).

## Capabilities

### New Capabilities

- `aggro`: interrupción del deambular, persecución y leash en monstruos.
- `target`: fijado de objetivo con clic, priorización en ataques y HUD.

### Modified Capabilities

(none)

## Impact

- `monster.gd`, `player.gd`, `hud.gd`, sim en `main.gd`, pista en `main.tscn`.
- Sin cambios en datos, balance de daño, exportador ni `.glb`.
- El loro y los repliegues de `aethermere-anim` se conservan.
