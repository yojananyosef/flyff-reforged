## Context

Specs estables: `game-data` (items con precio), `gameplay` (fórmulas con
`base_attack`/`base_defense`), `skills`, `audio`. Pell (`npc_002`,
mercader, `dlg_pell_intro`) no está en escena; la interacción E solo
conoce a Maren.

## Goals / Non-Goals

**Goals:**

- Loop económico cerrado: cazar → oro/drops → vender/comprar → equipar →
  cazar mejor.
- Equipo con efecto real y visible (stats + etiqueta en inventario).
- Tienda usable con ratón y verificable sin input (API en jugador).

**Non-Goals:**

- Regateo, stock limitado, reputación o tiendas múltiples.
- Sets, mejoras, ranuras o comparación de equipo.
- Moneda premium o persistencia (propuesta de guardado).

## Decisions

- **Lógica en el jugador, UI fina**: `buy`/`sell`/`equip` en `player.gd`,
  la tienda solo los llama. Alternativa: lógica en el panel — descartada;
  la simulación headless necesita la API sin UI.
- **Bonus en `items.json`** (`attack_bonus: 3`, `defense_bonus: 2`):
  los datos mandan, el código suma. Alternativa: tabla en código —
  descartada; duplica datos.
- **Venta a mitad, sin misión ni equipado**: evita romper quests y
  quedarse desnudo sin darse cuenta. Objetos `quest` no vendibles.
- **E abre el NPC más cercano** (grupo `npcs`): escala a futuros NPCs sin
  tocar `main.gd`. Diálogo igual para todos; Comerciar solo mercaderes.
- **Oro por muerte `nivel × 2`**: sin churn en `monsters.json`; documentado.

## Risks / Trade-offs

- [Riesgo] Farm infinito de liebres rompe economía → Mitigación: precios
  bajos de drops (liebre 3 → 1); economía de ejemplo, no final.
- [Riesgo] Equipar desde inventario confunde → Mitigación: botón Equipar
  + etiqueta de lo puesto; Desequipar devuelve al inventario.

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna.
