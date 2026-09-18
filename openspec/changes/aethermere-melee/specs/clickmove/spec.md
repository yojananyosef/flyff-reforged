## Purpose

Moverse con el ratón apuntando con la cruz, como alternativa a WASD.

## ADDED Requirements

### Requirement: Destino con clic

Con el ratón capturado, el clic cuyo rayo central impacta suelo SHALL fijar
ese punto como destino de marcha (anillo marcador visible). El jugador SHALL
caminar hacia él a su velocidad y detenerse a < 0.4 m, ocultando el anillo.
Cualquier entrada WASD SHALL cancelar el destino.

#### Scenario: Caminar al clic

- **WHEN** se fija un destino a 5 m y no se toca WASD
- **THEN** en ≤ 3 s el jugador está a < 0.5 m del punto

#### Scenario: WASD cancela

- **WHEN** hay destino activo y se pulsa W
- **THEN** el destino se limpia y manda el teclado
