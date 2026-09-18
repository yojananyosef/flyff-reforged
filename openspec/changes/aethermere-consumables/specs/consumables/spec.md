## Purpose

Objetos consumibles usables con efecto, cooldown y feedback.

## ADDED Requirements

### Requirement: Usar consumibles

`use_item(id)` SHALL exigir tipo consumible, al menos 1 unidad, efecto
aplicable (HP < max para `hp`, MP < max para `mp`) y cooldown libre
(3 s compartido); SHALL consumir 1 unidad, aplicar el efecto y emitir
`heal`; el botón Usar SHALL mostrar el cooldown mientras bloquea.

#### Scenario: Pan en combate

- **WHEN** con 50/100 HP se usa 1 pan (+25) de 3 unidades
- **THEN** el HP queda en 75, quedan 2 panes y el cooldown marca 3 s
