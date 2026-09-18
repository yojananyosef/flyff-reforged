## Why

El ratón vive capturado para girar la cámara y eso pelea con jugar con
cursor: seleccionar bichos, clicar al suelo o recolocar la vista exige
conmutar modos (ESC/I/tienda) y el pointer-lock falla sin gesto en web. El
esquema pedido es estándar RTS: cursor libre siempre y cámara solo mientras
se mantiene el botón derecho.

## What Changes

- Cursor `VISIBLE` por defecto y al cerrar cualquier UI (inventario, tienda,
  diálogo). Nada vuelve a `CAPTURED` fuera del drag.
- Mantener RMB SHALL girar la cámara (yaw + pitch, misma sensibilidad y
  límites); al soltar, el cursor queda libre donde esté. Se intenta
  `CAPTURED` durante el drag para giro infinito, con repliegue a relativo.
- La selección por clic SHALL usar siempre la posición del cursor
  (adiós rayo central); la cruz central se oculta.
- Pista de HUD: `RMB mirar · Clic ir/fijar · Doble-clic auto`.
- Sim: el modo por defecto es visible.

## Capabilities

### New Capabilities

- `freelook`: cursor libre por defecto y cámara solo con RMB.

### Modified Capabilities

- `target`: el rayo de selección sale del cursor, no del centro.

## Impact

- `player.gd`, `hud.gd` (2 cierres), `dialogue_panel.gd` (1 cierre), pista
  en `main.tscn`. Sin cambios en combate, agro ni datos.
