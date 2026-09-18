## Purpose

El jugador elige a qué monstruo pega con el ratón y ve su estado, en vez
de golpear siempre "al más cercano" a ciegas.

## Requirements

### Requirement: Fijar objetivo con clic

Con el cursor libre, el clic SHALL lanzar el rayo desde la posición del
cursor hasta 100 m; si impacta un monstruo, SHALL fijarlo como objetivo. La
cruz central se oculta (ya no es el punto de mira). Los clics con
inventario/tienda/diálogo abiertos son de la UI y no llegan al mundo. Si
además está en rango de ataque, SHALL golpearlo; si no, solo lo fija y
avisa en consola. Clic sin impacto conserva el objetivo y aplica el ataque
clásico al más cercano.

#### Scenario: Fijar y golpear

- **WHEN** se hace clic sobre un monstruo a 2 m
- **THEN** queda fijado y recibe el daño del básico

#### Scenario: Fijar lejos

- **WHEN** se hace clic sobre un monstruo a 30 m
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

### Requirement: HUD de objetivo

El HUD SHALL mostrar una etiqueta con el nombre y HP del objetivo
(`Objetivo: -` si no hay). No hay punto de mira central (cursor libre).

#### Scenario: Etiqueta

- **WHEN** se fija una liebre con 30/30
- **THEN** la etiqueta muestra su nombre y `30/30`
