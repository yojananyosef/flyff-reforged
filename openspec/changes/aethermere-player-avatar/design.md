## Context

Specs estables: `skin` (exportador skinned+animado, montaje con
repliegue en `monster.gd`), `anim` (walk en marcha, atk por golpe),
`melee` (punch de escala en `player.gd::_swing_fx`). Evidencia previa en
`docs/skin-proof/`. El cliente está en `~/Downloads/Flyff_US_extracted`.

## Goals / Non-Goals

**Goals:**

- Un `.glb` de jugador: 5 piezas SKIN + esqueleto `mvr_male` + 3
  animaciones, importable en Godot sin errores.
- Integración mínima que no rompa el slice (colisión y lógica intactas,
  repliegue a cápsula).
- Verificación visual (captura) + SIM-QUEST PASS con checks de avatar.

**Non-Goals:**

- Texturas (mallas en gris, como monstruos).
- Equipamiento visible intercambiable (solo set base Vag01 + cabeza 06).
- Personaje femenino (solo `mvr_male`; el femenino sigue el mismo patrón).
- Retarget o blending avanzado (cortes directos stand/walk/atk1).

## Decisions

- **Piezas Vag01 + cabeza/pelo 06**: el set inicial de vagabundo
  (`Part_mVag01Upper/Hand/Foot`) no trae casco; se completa con
  `Part_maleHead06` + `Part_maleHair06`. Todas son SKIN y parsean con
  `o3d_parser` (verificado: 444+100+106+182+113 vértices).
- **Variante `-C` (puños)**: `GenFStand1-C` (41 f), `GenFRunning1-C`
  (31 f), `GenFAtk1-C` (41 f); las tres animan los 30 huesos del
  esqueleto. `-C` es la postura de combate sin arma del vagabundo;
  coherente con el ataque básico actual.
- **`walk` = `GenFRunning1-C`**: no existe `GenFWalk` humano; a 5 m/s el
  jugador corre de facto, y el clip de carrera evita el deslizamiento
  lento. Se exporta con nombre `walk` para reutilizar la convención de
  `monster.gd`.
- **Multi-`--o3d` en el exportador**: `build()` acepta lista y concatena
  primitivas bajo el mismo `skin`/`skeleton`; no cambia el caso de un
  solo `.o3d` (monstruos intactos).
- **Montaje espejo de `monster.gd`**: `_mount_model`, `_find_anim`,
  `_play_anim`, `_play_locomotion`, `_try_attack_anim` adaptados; el
  giro de la malla sigue en `body_mesh` cuando no hay modelo y pasa al
  nodo `Model` cuando lo hay. `_swing_fx` conserva el punch como
  repliegue sin modelo.

## Risks / Trade-offs

- [Riesgo] Proporciones raras (cabeza/pelo de otro set) → Mitigación:
  captura previa; cabeza 06 y pelo 06 son del mismo set.
- [Riesgo] `walk` a ritmo de carrera con marcha lenta → Mitigación: se
  acepta; el ajuste fino de velocidad es pulido posterior.
- [Riesgo] `.glb` pesado en repo → Mitigación: no se versiona;
  `setup_player_model.py` lo deriva.

## Migration Plan

No aplica. Rollback = revert + borrar `PlayerMvr.glb` (repliegue).

## Open Questions

- ¿30 fps es la velocidad real? Igual que en skin: a ojo, pendiente de
  testers.
