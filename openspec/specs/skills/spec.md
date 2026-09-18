# skills Specification

## Purpose
Convertir `skills.json` en sistema: stats, fórmula de daño físico,
skills activas de warden y su barra en el HUD.

## Requirements

### Requirement: Fórmula de daño físico

Todo daño físico SHALL calcularse como `max(1, ataque + poder − defensa)`;
el ataque básico usa poder 0 y el daño por contacto de monstruo también.
`Bulwark Stance` SHALL reducir el daño recibido a la mitad 5 s.

#### Scenario: Números exactos

- **WHEN** un warden (ataque 5) golpea básico a `mon_004` (defensa 0)
- **THEN** el daño es 5; con Ember Slash (poder 12) es 17

### Requirement: Skills activas

`cast_skill(id)` SHALL exigir nivel (`level_required`), MP (`mp_cost`) y
cooldown (Ember 4 s, Bulwark 20 s, Bandage 15 s); Ember SHALL curar
alcance 3.0 y solo consumir cooldown al golpear; Bandage SHALL curar 30%
del HP máximo; las skills SHALL aprenderse al subir de nivel.

#### Scenario: Rotación completa

- **WHEN** un nivel 3 con MP llena usa 1/2/3
- **THEN** Ember daña, Bulwark activa el buff 5 s y Bandage cura, cada
  una entra en cooldown y el MP baja según coste

### Requirement: Barra de skills en HUD

El HUD SHALL mostrar un slot por skill (tecla, nombre, cooldown,
bloqueo por nivel/MP) y un indicador mientras Bulwark está activo.

#### Scenario: Slots construidos

- **WHEN** arranca la escena principal
- **THEN** hay 3 slots y el de Ember está listo para un nivel 1
