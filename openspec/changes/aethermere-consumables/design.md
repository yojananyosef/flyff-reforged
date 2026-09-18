## Context

Specs estables: `game-data` (tipos weapon/armor/consumable/material/quest),
`gameplay` (inventario con cantidades). El inventario ya muestra todo;
falta la acción de usar.

## Goals / Non-Goals

**Goals:**

- Pan y tónico útiles desde nivel 1 con reglas claras y testeadas.
- Sin spam: un cooldown visible evita beberse 10 panes en un segundo.

**Non-Goals:**

- Nuevos consumibles, crafteo o efectos temporales (buffs de comida).
- Hotkeys dedicadas (el botón basta en el MVP).

## Decisions

- **Efecto en datos (`use_effect: {hp, mp}`), cooldown en código (3 s)**:
  los números mandan los datos; el tiempo es regla global documentada
  aquí. Alternativa: todo en datos — descartada; un solo cooldown
  compartido no necesita 5 campos.
- **No usar a tope**: si HP y MP están llenos (o el efecto aplicable es
  0), se rechaza sin consumir. Alternativa: permitir desperdicio —
  descartada; frustra por accidente.
- **Cooldown compartido pan/tónico**: simple y anti-spam. Alternativa:
  por objeto — descartada por ahora.
- **Mismo SFX `heal`** para ambos: ya existe y comunica "recuperar".

## Risks / Trade-offs

- [Riesgo] Tónico barato trivializa el MP → Mitigación: 20 MP por 8 de
  precio; la regen (3/s) ya existe y el tónico es para emergencias.
- [Riesgo] Cooldown invisible confunde → Mitigación: el botón muestra
  el tiempo restante mientras bloquea.

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna.
