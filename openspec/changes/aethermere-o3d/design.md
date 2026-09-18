## Context

Referencia: `~/flyff-work/o3d-reader/FlyFFO3DReader-OPENGL/`
(`LoadedObject::LoadObject/LoadGMObject/LoadTMAni`, `CMotion::ReadTM`,
structs en `Utils.h`/`CMotion.h`). Tamaños: SKINVERTEX 44, NORMALVERTEX
32 (+12 si bump), GLWMATERIAL9 68, MATERIAL_BLOCK 136, TM_ANIMATION 28,
MOTION_ATTR 12. Tipos: NORMAL 0, SKIN 1, BONE 2.

## Goals / Non-Goals

**Goals:**

- Geometría exacta: cada byte del archivo asignado a un campo.
- `.glb` que Godot importa sin errores con materiales nombrados.
- Skinning preservado (joints/weights) aunque el esqueleto se fusione
  en Fase 5 (los huesos base del `.o3d` no traen nombres).

**Non-Goals:**

- Sustituir placeholders en el juego (Fase 5).
- Texturas `.dds` (conversor aparte; el `.glb` guarda el nombre).
- Animaciones embebidas más allá de preservarlas en JSON.

## Decisions

- **Sin dependencias** (ni `pygltflib`): el escritor GLB cabe en ~120
  líneas con `struct`+`json`. Alternativa: pygltflib — descartada;
  coherente con parsers sin deps.
- **Tamaño de vértice por flag `bump`** (el lector C++ siempre usa no-bump
  y probablemente rompe modelos con bump): el batch con cuadre de bytes
  dirime cada caso.
- **Nombre de hueso en `ReadTM` siempre leído** (el `if (nLen > 32)` del
  C++ huele a artefacto de port): el cuadre de bytes lo confirma o
  corrige.
- **`matIdx` como 2×u16 empaquetados** (joints) con w1/w2 (weights):
  convención del campo; documentada como asunción hasta animar de verdad.
- **Matrices tal cual del archivo** (orden de floats preservado):
  Godot las interpreta; la captura visual confirma orientación.

## Risks / Trade-offs

- [Riesgo] Archivos con `bump` o LOD múltiple descuadran → Mitigación:
  batch mide; los que fallen quedan listados para análisis, no bloquean.
- [Riesgo] Convención de matrices traspuesta → Mitigación: captura de
  3 modelos; si salen girados se traspone una vez en el conversor.
- [Riesgo] `matIdx` con otro empaquetado → Mitigación: en bind pose el
  render es idéntico; se revisa al fusionar esqueletos (Fase 5).

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna; las tres asunciones se verifican en esta propuesta.
