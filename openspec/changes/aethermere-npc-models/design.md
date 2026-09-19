## Context

Specs estables: `skin`/`skin-texture` (exportador + `--tex-dir`),
`player-avatar` (montaje con repliegue en `player.gd`), `props`
(snap a `ground_height`). Evidencia: `Mvr_NpcSebrance` y `mvr_NpcBato`
traen `.o3d`+`.chr`+`stand/idle1/walk`+`.dds` sueltos de un solo
material; `main.tscn` tiene `$NPC`/`$NPC2` (StaticBody3D + cápsula +
NameLabel) y `npc_setup()` solo fija `npc_id` y altura.

## Goals / Non-Goals

**Goals:**

- 2 `.glb` texturados con idle en bucle, encarados al spawn, snap al
  suelo existente; SIM-QUEST PASS + captura en navegador.
- `setup_npcs.py` deriva todo desde el cliente con PIL.

**Non-Goals:**

- Gestos al hablar, más NPC, cambios de diálogo/tienda.

## Decisions

- **Espejo de `setup_models.py`**: lee `npcs.json` (campo `model`) y
  llama a `o3d_to_skinglb.py --tex-dir`; sin duplicar lógica de
  conversión.
- **Montaje en `npc_setup()`**: helper local `_mount_npc(node)` que
  busca el primer `AnimationPlayer`, reproduce `stand`/`idle1` en
  bucle y oculta la cápsula; el `NameLabel` y la colisión quedan
  intactos.
- **Encarado al spawn (+PI por frontal -Z)**: `rotation.y =
  atan2(spawn-npc) + PI`, igual que el avatar; se verifica en captura.
- **Colisión intacta**: el StaticBody3D y su cápsula de colisión no se
  tocan; solo se oculta la malla visible.

## Risks / Trade-offs

- [Riesgo] NPC de espaldas (yaw mal supuesto) → Mitigación: captura
  en navegador con ambos NPC de frente antes de cerrar.
- [Riesgo] Escala rara del modelo vs cápsula → Mitigación: captura;
  el snap usa la misma `y` (pies al suelo si el origen del .o3d está
  en los pies, como el jugador).
- [Riesgo] Sin `.ani` idle en algún NPC futuro → Mitigación: cascada
  `stand` → `idle1` → `idle` → `Default`, como el avatar.

## Migration Plan

No aplica. Rollback = borrar `.glb` de NPC (repliegue).

## Open Questions

- Ninguna bloqueante.
