## Context

`main.tscn` trae `sky_env` con `background_mode = 1` (color
0.05/0.07/0.12) + `Sun` DirectionalLight3D con sombras + ambiente
(0.6/0.65/0.75 × 0.7). Export web en Compatibility: el
`ProceduralSkyMaterial` funciona sin cómputo extra relevante.

## Goals / Non-Goals

**Goals:**

- Cielo diurno cálido coherente con la pintura del terreno (arena
  crema) + niebla sutil; captura en navegador + SIM-QUEST PASS.

**Non-Goals:**

- Día/noche, nubes, clima.

## Decisions

- **`Sky` + `ProceduralSkyMaterial`**: sin texturas ni shaders
  propios; `background_mode = 2`, ambiente sigue de Sky (source 2).
- **Paleta**: cenit (0.35, 0.55, 0.88), horizonte (0.95, 0.87, 0.70),
  suelo (0.55, 0.48, 0.36); sol del material alineado a ojo con el
  `Sun` existente (energía 1.0, sin disco exagerado).
- **Niebla estándar sutil**: `fog_enabled`, color (0.9, 0.85, 0.72),
  densidad baja (~0.01) solo para fundir dunas lejanas; si la captura
  lo muestra lavado se retira.

## Risks / Trade-offs

- [Riesgo] Niebla lava la escena → Mitigación: captura y ajuste /
  retirada.
- [Riesgo] Cielo distinto entre Compatibility y PC → Mitigación: la
  verificación es en el build web (lo que juega el usuario).

## Migration Plan

No aplica. Rollback = revert del `.tscn`.

## Open Questions

- Ninguna bloqueante.
