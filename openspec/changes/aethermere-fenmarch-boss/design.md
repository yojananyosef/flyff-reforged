## Context

Ver propuesta (Why). Estado: `fenmarch` con 4 monstruos (006 nivel 4, 007 nivel 5, 008 nivel 6, 009 nivel 4), cadena 201–205 donde la 205 pide 1×mon_006 y no desbloquea nada. Spawn único por zona, `_spawn_monsters()` genera 1 por ficha (5 solo mon_001). SIM-QUEST cubre viaje + 201. Nivel: `max_exp *= 1.5`, daño `max(1, atk+poder−def)`.

## Goals / Non-Goals

**Goals:**

- Curva 4–8 sin huecos con boss 8 memorable y quest 206 de cierre.
- SIM-QUEST PASS con 201–206 sin romper los 179 checks.

**Non-Goals:**

- Nuevos modelos/animaciones, loot épico, tercera zona, mapa del mundo.

## Decisions

- **010 Ridge Stalker nivel 7 (Mvr_Buur, hp 150/atk 19/def 6/exp 58) + 011 Storm Crow nivel 7 (Mvr_PetParrot, hp 110/atk 18/def 4/exp 54) + 012 Fenmarch Alpha Prime nivel 8 boss (Mvr_PetDog1 escalado, hp 320/atk 24/def 7/exp 180, aggro 9)**: reutilizar modelos como en 006–009 (cero conversiones); el boss escala por stats, no por mesh nuevo. Alternativa (nuevo .glb) descartada por costo.
- **205 desbloquea 206; 206 pide 1×mon_012, recompensa 650 EXP + item_009×2**: espejo del remate 110 (alpha + colmillos), cierra el arco sin economía nueva.
- **Boss count 1 en `_spawn_monsters` sin cambios de lógica**: entra por `zones.json fenmarch.monsters` + `game_data.monsters`; el sim lo cuenta como parte del set Fenmarch.
- **Diálogo Sella con nodo boss**: extiende `dlg_sella_intro` (quest_board menciona al alpha verdadero), sin diálogo nuevo.

## Risks / Trade-offs

- [Riesgo] Boss 24 atk mata al warden nivel 4–5 → Mitigación: llega con equipo/tonics de la 201–205 + Bulwark; el sim verifica daño, no balance fino.
- [Riesgo] EXP 650 + 180 rompe curva → Mitigación: es final de arco, aceptado; `max_exp *= 1.5` absorbe.
- [Riesgo] Reutilizar Dog1 para boss confunde con 006 → Mitigación: nombre/stats/aggro distintos; sin mesh nuevo por alcance.

## Migration Plan

No aplica (datos nuevos; Ironhold intacto). Rollback: revert de `data/` + sim.

## Open Questions

- Ninguna bloqueante.
