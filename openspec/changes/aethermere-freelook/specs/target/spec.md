## MODIFIED Requirements

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
