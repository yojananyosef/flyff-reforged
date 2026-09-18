## Purpose

Ironhold pisa el terreno real del cliente en vez de un plano liso.

## ADDED Requirements

### Requirement: Parser .lnd verificado en batch

El parser SHALL leer cabecera y rejillas de altura de los 900 tiles de
WdMadrigal sin errores, con alturas en rango plausible y continuidad de
bordes entre tiles vecinos (muestreo), y SHALL documentar el formato en
`docs/lnd-research.md`.

#### Scenario: Batch WdMadrigal

- **WHEN** se ejecuta el parser sobre los 900 `.lnd`
- **THEN** 900/900 parsean, las alturas caen en ±500 m y ≥ 95 % de los
  bordes muestreados continúan a < 1 m

### Requirement: Suelo real con repliegue

El juego SHALL usar la malla de terreno + colisión bajo el área de juego
cuando existan los `.glb`; si no existen SHALL mantener el plano actual.
El jugador SHALL apoyar en el suelo (sin hundirse ni flotar > 0.5 m).

#### Scenario: Arranque con terreno

- **WHEN** existen `terrain_*.glb` y arranca la escena
- **THEN** el Ground visible es la malla y el jugador reposa sobre ella

#### Scenario: Repliegue sin terreno

- **WHEN** no hay `.glb` de terreno
- **THEN** el juego arranca con el plano de 40×40 como hoy
