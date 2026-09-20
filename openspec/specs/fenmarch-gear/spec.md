## Purpose

El ridge exige acero del ridge: un tier de equipo 4–8 comprable y de recompensa que convierte el muro de stats del boss en una caza exigente pero justa.

## Requirements

### Requirement: Tier de equipo Fenmarch

El juego SHALL ofrecer 2 armas y 2 armaduras de tier Fenmarch con `level_required` 4/4/7/7, bonus crecientes sobre el tier Ironhold (+8/+6 y +14/+9) y precios 90/80/220/200; equiparlas SHALL reflejarse en `attack_stat()`/`defense_stat()`.

#### Scenario: Build completa Alpha

- **WHEN** un nivel 7+ equipa la espada Alpha (+14) y la placa Storm (+9)
- **THEN** `attack_stat()` es 19 y `defense_stat()` es 10

#### Scenario: Progresión Ridge intermedia

- **WHEN** un nivel 4+ equipa la espada Ridge (+8) y el abrigo Ridge (+6)
- **THEN** `attack_stat()` es 13 y `defense_stat()` es 7
