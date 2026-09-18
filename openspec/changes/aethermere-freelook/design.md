# Design: aethermere-freelook

## Estado (`player.gd`: `_rmb_held`)

- `_ready`: `MOUSE_MODE_VISIBLE`. Se elimina toda vuelta a `CAPTURED`
  (`hud.gd` ×2, `dialogue_panel.gd` ×1 pasan a `VISIBLE`).
- `InputEventMouseButton` derecho: `pressed=true` → `_rmb_held = true` e
  intento de `CAPTURED` (gesto válido, giro infinito); `pressed=false` →
  `_rmb_held = false` + `VISIBLE`.
- `InputEventMouseMotion`: solo rota si `_rmb_held` (mismo yaw/pitch/límites
  de hoy). Sin drag, el movimiento no toca la cámara.
- `_can_world_click()`: sin rama de capturado; solo bloquea con
  inventario/tienda/diálogo abiertos. El clic izquierdo no interfiere con
  el drag derecho.
- `_click_hit()`: siempre posición del cursor
  (`get_viewport().get_mouse_position()`); la tolerancia de 140 px pasa a
  medirse al cursor. La cruz (`_crosshair`) se oculta al crearla.

## Verificación

- Sim PASS + `mouse_mode == VISIBLE` por defecto.
- Navegador: mover el ratón no rota; drag RMB rota yaw+pitch; clic sobre
  bicho fija objetivo; 0 errores.
