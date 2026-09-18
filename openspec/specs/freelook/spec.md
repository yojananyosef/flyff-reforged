## Purpose

Mirar alrededor solo cuando el jugador lo pide, sin perder nunca el cursor.

## Requirements

### Requirement: Cursor libre por defecto

El ratón SHALL estar visible al arrancar y al cerrar inventario, tienda o
diálogo. Ningún flujo lo deja en `CAPTURED` salvo el drag activo.

#### Scenario: Arranque

- **WHEN** arranca el juego
- **THEN** `Input.mouse_mode` es `VISIBLE`

### Requirement: Mirar con botón derecho

Mientras el RMB está pulsado, el movimiento del ratón SHALL girar la cámara
(yaw en el pivote, pitch en el brazo, mismos límites); al soltarlo SHALL
volver a cursor libre. Durante el drag se intenta captura para giro
infinito.

#### Scenario: Drag

- **WHEN** se mantiene RMB y se mueve el ratón 200 px a la derecha
- **THEN** la cámara gira yaw a la derecha y el modo vuelve a visible al
  soltar
