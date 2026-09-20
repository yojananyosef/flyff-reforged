## Purpose

Fenmarch es una segunda zona jugable con progresión desde Ironhold mediante portales.

## ADDED Requirements

### Requirement: Zona Fenmarch jugable

El juego SHALL cargar el terreno real de los tiles 15–16/05–06 con
spawn apoyado, vegetación del atlas, props y 4 monstruos propios
cuando la zona actual es `fenmarch`; el HUD SHALL mostrar su nombre.

#### Scenario: Llegada a Fenmarch

- **WHEN** se viaja a `fenmarch`
- **THEN** el jugador aparece en su spawn sobre el suelo, con sus
  monstruos y su NPC visibles

#### Scenario: Cadena 201–205

- **WHEN** se completa la 110 y se habla con el warden de Fenmarch
- **THEN** la 201 está disponible y la cadena avanza hasta la 205

### Requirement: Viaje bidireccional

Cada zona SHALL tener un portal visible; al pulsar `E` junto a él
SHALL guardar, cambiar de zona y recargar la escena en el spawn de
destino.

#### Scenario: Ida y vuelta

- **WHEN** se usa el portal de Ironhold y luego el de Fenmarch
- **THEN** se vuelve al spawn de Ironhold con progreso intacto
