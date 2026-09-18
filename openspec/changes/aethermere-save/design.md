## Context

Specs estables: `gameplay` (estado en jugador + `quest_manager`),
`game-data` (definiciones). No hay persistencia; los autoloads
sobreviven a recargas de escena y hay que resetearlos a mano.

## Goals / Non-Goals

**Goals:**

- Cerrar y reabrir conservando todo lo que el jugador ganó.
- Formato inspeccionable y versionado; corrupción = nueva partida con aviso.
- Una sola ranura; suficiente para el MVP.

**Non-Goals:**

- Múltiples ranuras, guardado en nube o anti-trampas.
- Guardar posición exacta de cada monstruo (respawnean; solo importa el
  jugador y las misiones).

## Decisions

- **JSON en `user://`** con `version: 1`: legible, depurable y portable.
  Alternativa: ConfigFile — descartada; el JSON casa con `data/`.
- **Autoload `save_manager` separado** (no dentro de `GameData`):
  `GameData` son definiciones estáticas; el progreso es otro dominio.
- **Auto-carga al arrancar + F5/F8**: cero fricción para probar;
  F8 = borrar + `reset()` de managers + recarga de escena. Alternativa:
  menú de título — fuera de scope; el arranque directo sigue siendo el MVP.
- **Auto-guardado al completar misión**: el progreso que más duele
  perder se persiste solo. Muertes no guardan (respawn ya existe).

## Risks / Trade-offs

- [Riesgo] Save corrupto bloquea el arranque → Mitigación: parse
  defensivo; si falla, aviso + partida nueva (el archivo roto se renombra
  a `.bak`).
- [Riesgo] F8 accidental borra todo → Mitigación: es MVP sin menú; se
  documenta en el hint. Confirmación cuando haya UI de verdad.

## Migration Plan

No aplica. Rollback = revert. Saves viejos sin `version` se rechazan
como corruptos (no existen en la práctica: feature nueva).

## Open Questions

- Ninguna.
