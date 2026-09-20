## Context

Ver propuesta (Why). Estado: `quest_manager` terminal (`done`), slots `$NPC/$NPC2` con 1 NPC en Fenmarch, `add_exp` cura sin crecer, avatar `PlayerMvr.glb` único con encarado vía `_model.rotation` y repliegue a cápsula.

## Goals / Non-Goals

**Goals:**

- Bucle post-206 jugable, compras en Fenmarch, niveles con fondo, tiers distinguibles.
- SIM-QUEST PASS con los 218 checks intactos + nuevos.

**Non-Goals:**

- Tercera zona, minimapa, sets con bonus, `.glb` de armas, re balance del boss.

## Decisions

- **Flag `repeatable` en quest**: 207 (3×mon_010, EXP + pan), 208 (4×mon_011, EXP + tónico), 209 (2×mon_007, EXP alta); recompensas sin equipo ni oro directo (el oro sigue viniendo de muertes); `_complete` omite `done` si repetible → `available_quests` la reoferta. El viaje reconstruye monstruos (bucle ya establecido en la 109 con 8/5). Alternativa (resets diarios con fecha) descartada por complejidad de reloj.
- **npc_004 mercader Fenmarch con `Mvr_NpcSebrance` + `dlg_bram_intro`**: reutiliza modelo de Maren (otra zona, sin choque) y rol `merchant` (Comerciar sale gratis por rol). Cabe en `$NPC2` (máx. 2/zona).
- **+12 HP / +4 MP por nivel en `add_exp`**: sin tocar ataque/defensa → los asserts exactos de builds (13/19) y del boss siguen válidos. Saves viejos conservan `max_hp` (ya persistido); documentado.
- **Props procedurales hijos de `_model` (repliegue: hijos de self)**: `GearBlade` (BoxMesh hoja + guarda, color por tier, largo ∝ bonus) a un costado + 2 hombreras (tamaño ∝ bonus armadura); `_refresh_gear_visual()` en equip/unequip/_mount_model. Sin assets nuevos; la captura WebGL del sandbox no aplica (sin GPU) → el sim verifica existencia/color.

## Risks / Trade-offs

- [Riesgo] Repetible aceptada dos veces sin completar → Mitigación: `accept_quest` ya ignora repetidos activos.
- [Riesgo] Recompensas repetibles inflan economía → Mitigación: EXP moderada + consumibles (no equipo/oro directo); el oro sigue viniendo de muertes.
- [Riesgo] Props chocan con animación atk1 → Mitigación: hijos de `_model` (siguen encarado y clips); geometría simple sin skinning.
- [Riesgo] Crecimiento HP facilita boss viejo → Mitigación: +12/nivel es fondo, no TTK; los asserts del boss son cotas que siguen pasando.

## Migration Plan

No aplica. Rollback: revert de `data/` + 2 scripts + sim.

## Open Questions

- Ninguna bloqueante.
