## Context

Ver propuesta (Why). Estado: 2 equipos (`item_001` +3, `item_002` +2), stock de 4, `add_exp` sin crecimiento de stats, boss 320/24/7. Patrón de recompensas: items directos en `rewards.items`.

## Goals / Non-Goals

**Goals:**

- Build Ridge jugable a nivel 4 y build Alpha que hace justo al boss con consumibles.
- Recompensas garantizan la progresión aunque el oro no alcance; la tienda permite recomprar.
- SIM-QUEST PASS con asserts numéricos de balance.

**Non-Goals:**

- Mercader en Fenmarch, crecimiento por nivel, sets/bonus, tercera zona.

## Decisions

- **011 Ridge Blade +8 (lvl 4, 90 oro) + 013 Ridge Coat +6 (lvl 4, 80) + 012 Alpha Fang Blade +14 (lvl 7, 220) + 014 Stormplate +9 (lvl 7, 200)**: reutiliza pipeline de equipo existente (sin modelos nuevos; el equipo modifica stats, no mesh). Precios calibrados al ingreso (oro inicial 30 + nivel×2 por muerte + materiales a mitad + recompensas).
- **202 → +Ridge Blade, 204 → +Ridge Coat, 206 → +Alpha Blade (conservando consumibles/colmillos actuales)**: progresión garantizada espejo de la 101–110; la tienda además los vende.
- **Sin mercader nuevo**: Pell sigue siendo el único mercader; el portal Ironhold↔Fenmarch ya existe. Nuevo NPC con modelo/diálogo queda fuera por alcance.
- **Balance objetivo con build Alpha (atk 19/def 10)**: básico al boss 12/turno (~27 turnos), Ember 24 (~14), boss al jugador 14/turno (7 con Bulwark) → caza larga con tónicos/vendas, no one-shot en ningún sentido.

## Risks / Trade-offs

- [Riesgo] Precios inalcanzables sin farmeo → Mitigación: las recompensas dan el equipo clave gratis; la tienda es recomprar/recuperar.
- [Riesgo] Boss aún duro para nivel 6–7 → Mitigación: aceptado (boss final nivel 8); el sim verifica números, no manos del jugador.
- [Riesgo] Cambiar recompensas rompe saves viejos a mitad de cadena → Mitigación: solo añade items a rewards futuras; saves con 202/204/206 ya completadas no las re-otorgan (aceptado).

## Migration Plan

No aplica (datos + stock). Rollback: revert de `data/` + `hud.gd` + sim.

## Open Questions

- Ninguna bloqueante.
