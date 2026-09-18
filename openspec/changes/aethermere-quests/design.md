## Context

Specs estables: `game-data` (2 misiones), `gameplay` (quest_manager
genérico, tracker de una activa). Solo existe tipo de objetivo `kill`;
`collect` queda fuera (propuesta futura).

## Goals / Non-Goals

**Goals:**

- 10/10 misiones del MVP jugables de principio a fin.
- Pell deja de ser decorado: da 3 misiones.
- Jefe final (lobo alfa, `mon_005` ×1 con texto propio) como cierre.

**Non-Goals:**

- Nuevos tipos de objetivo, monstruos o zonas.
- Recompensas de equipo (el equipo se compra; no se regala poder).

## Decisions

- **Todo `kill` con bestiario existente**: reaprovecha spawns, tracker y
  sim sin código nuevo. Alternativa: objetivos `collect` — descartada;
  exige manager + UI + validación nuevas por poco valor MVP.
- **Nodo `quest_board` genérico** en vez de 8 textos de oferta: el botón
  Aceptar ya resuelve la misión disponible; evita 8 nodos casi idénticos.
- **Recompensas EXP + consumibles/trofeos** (nunca equipo): la tienda
  sigue siendo la vía del poder; los trofeos (mote, fang) anticipan crafteo.

## Risks / Trade-offs

- [Riesgo] 8 misiones de caza se sienten repetitivas → Mitigación:
  escalado de dificultad y alternancia Maren/Pell; la variedad de
  objetivos queda para post-MVP.
- [Riesgo] Lobos (nivel 3) Tanner bloquean a nivel 2 → Mitigación: 105
  pide solo 2 y llega con ~400 EXP acumulada (nivel 3-4).

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna.
