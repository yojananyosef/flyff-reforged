## Purpose

Que el progreso sobreviva al cierre del juego: una ranura local con
guardado manual, auto-guardado en hitos y carga al arrancar.

## ADDED Requirements

### Requirement: Guardar y cargar progreso

El autoload SHALL guardar en `user://aethermere_save.json` la zona,
posición, stats, oro, inventario, equipo y misiones; SHALL cargarlo al
arrancar si existe; SHALL tratar un archivo corrupto como partida nueva
con aviso (renombrando a `.bak`).

#### Scenario: Cierre y reapertura

- **WHEN** se guarda con 45 de oro y misión 103 activa en 2/4 y se
  reinicia
- **THEN** al arrancar el oro es 45 y la 103 sigue activa en 2/4

### Requirement: Controles de partida

F5 SHALL guardar, F8 SHALL empezar partida nueva (borrar + reset +
recarga) y completar una misión SHALL auto-guardar.

#### Scenario: Nueva partida

- **WHEN** se pulsa F8 con progreso
- **THEN** el archivo desaparece, las misiones se vacían y el jugador
  reaparece en el spawn con valores iniciales
