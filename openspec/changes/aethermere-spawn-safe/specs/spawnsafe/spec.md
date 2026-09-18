## Purpose

El jugador puede orientarse al aparecer sin morir antes de tocar nada, y
siempre se ve qué build corre.

## ADDED Requirements

### Requirement: Protección al aparecer

Al aparecer o resucitar, el jugador SHALL tener 6 s de protección: los
monstruos no le fijan agro (y sueltan el que tuvieran), el contacto no le
hace daño y `take_mob_damage` no aplica nada. Atacar o castear SHALL
romperla; moverse no.

#### Scenario: Gracia inicial

- **WHEN** un lobo a 5 m con el jugador recién aparecido (protegido)
- **THEN** tras 1 s no tiene agro y el HP sigue al máximo

#### Scenario: Ruptura

- **WHEN** el jugador protegido golpea con un básico
- **THEN** la protección se apaga en ese acto

### Requirement: Etiqueta de build

El HUD SHALL mostrar abajo a la derecha el tag del build (`build <corto>`)
o `dev` si no hay sello (partida local sin exportar).

#### Scenario: Sello

- **WHEN** el juego corre del export web con `build.json`
- **THEN** la etiqueta muestra el tag sellado, no `dev`
