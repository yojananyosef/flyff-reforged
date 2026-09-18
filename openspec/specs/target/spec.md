## Purpose

El jugador elige a qué monstruo pega con el ratón y ve su estado, en vez
de golpear siempre "al más cercano" a ciegas.

## Requirements

### Requirement: Fijar objetivo con clic

Con el ratón capturado, el clic SHALL lanzar un rayo desde el centro de
la pantalla (punto de mira) hasta 100 m; con el ratón libre (sin
pointer-lock) SHALL usar la posición del cursor. Si impacta un monstruo,
SHALL fijarlo como objetivo. Los clics con inventario/tienda/diálogo
abiertos son de la UI y no llegan al mundo. Si además está en rango de
ataque, SHALL golpearlo; si no, solo lo fija y avisa en consola. Clic sin impacto conserva el objetivo y
aplica el ataque clásico al más cercano.

#### Scenario: Fijar y golpear

- **WHEN** se hace clic con un monstruo en el punto de mira a 2 m
- **THEN** queda fijado y recibe el daño del básico

#### Scenario: Fijar lejos

- **WHEN** se hace clic con un monstruo en el punto de mira a 30 m
- **THEN** queda fijado pero no recibe daño

### Requirement: Priorizar objetivo en ataques

El básico y Ember Slash SHALL golpear al objetivo si es válido y está en
rango, aunque haya otro monstruo más cerca. Sin objetivo (o inválido), SHALL
usar el más cercano como hasta ahora. El objetivo inválido (muerto/liberado)
SHALL limpiarse solo.

#### Scenario: Prioridad

- **WHEN** hay un monstruo a 1 m y el objetivo fijado a 2 m, ambos en rango
- **THEN** el básico daña al objetivo, no al más cercano

#### Scenario: Limpieza

- **WHEN** el objetivo muere y se libera
- **THEN** el jugador lo limpia en el siguiente frame físico

### Requirement: HUD de objetivo y punto de mira

El HUD SHALL mostrar un punto de mira en el centro y una etiqueta con el
nombre y HP del objetivo (`Objetivo: -` si no hay).

#### Scenario: Etiqueta

- **WHEN** se fija una liebre con 30/30
- **THEN** la etiqueta muestra su nombre y `30/30`
