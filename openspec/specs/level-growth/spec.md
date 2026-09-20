## Purpose

Subir de nivel se nota en el cuerpo: cada nivel da más fondo de HP/MP para que la progresión no dependa solo del equipo.

## Requirements

### Requirement: Crecimiento por nivel

Cada nivel SHALL sumar +12 a `max_hp` y +4 a `max_mp` (además de curar al máximo como hoy); ataque y defensa base SHALL quedar intactos.

#### Scenario: Nivel con fondo

- **WHEN** un nivel 1 con 100/50 sube al 2
- **THEN** su máximo es 112/54 con HP/MP llenos
