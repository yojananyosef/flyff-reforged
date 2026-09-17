## Purpose

Esta capacidad cubre el proyecto Godot 4 mínimo jugable: escena principal, controlador de jugador en tercera persona con cámara orbital y HUD básico (HP/MP/EXP), cargando datos desde `data/`.

## ADDED Requirements

### Requirement: Movimiento del jugador en tercera persona

El jugador SHALL moverse con WASD, saltar con Espacio y rotar la cámara con el ratón, con gravedad aplicada y colisión contra el suelo.

#### Scenario: Movimiento básico

- **WHEN** el jugador mantiene pulsada la tecla de avance durante 1 segundo en la escena principal
- **THEN** el personaje se desplaza en la dirección de la cámara y la animación/posición se actualiza sin atravesar el suelo

### Requirement: HUD básico

El HUD SHALL mostrar barras de HP/MP/EXP y actualizarse cuando cambian los valores del jugador.

#### Scenario: Daño visible en HUD

- **WHEN** el HP del jugador se reduce (por comando de prueba o daño)
- **THEN** la barra de HP refleja el nuevo valor en menos de 1 frame visible y muestra el texto numérico actualizado

### Requirement: Carga de datos JSON

El proyecto SHALL cargar al arranque al menos `data/zones.json` y `data/dialogues.json` desde disco y exponer la zona inicial (`ironhold`) al gestor de juego.

#### Scenario: Arranque con datos

- **WHEN** se ejecuta la escena principal con los JSON presentes
- **THEN** el juego arranca sin errores, registra la zona actual como `ironhold` y muestra su `display_name` en el HUD o consola
