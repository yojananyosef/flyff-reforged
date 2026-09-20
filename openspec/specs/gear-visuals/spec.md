## Purpose

El Alpha se ve como Alpha: el arma y la armadura equipadas se distinguen a simple vista sin conversiones nuevas.

## Requirements

### Requirement: Equipo visible por tier

Al equipar un arma SHALL aparecer una hoja procedural junto al modelo (color y largo por tier: recluta gris, Ridge acero, Alpha brasa); al equipar armadura SHALL aparecer hombreras (tamaño por tier); al desequipar SHALL ocultarse. La lógica y colisión SHALL quedar intactas.

#### Scenario: Alpha a la vista

- **WHEN** se equipa la espada Alpha y la placa Storm
- **THEN** la hoja brasa y las hombreras grandes son visibles junto al modelo
