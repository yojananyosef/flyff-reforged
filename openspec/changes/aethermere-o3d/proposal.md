## Why

Todo lo visible son cápsulas: 6202 modelos del cliente esperan en
`models_raw` y el doc de investigación solo cubre el header. El lector
C++ de referencia documenta el cuerpo completo (`LoadGMObject`,
`ReadTM`, `LoadTMAni`), así que el riesgo es bajo: toca reimplementarlo
en Python y exportar a `.glb` para que Godot importe geometría real.

## What Changes

- `scripts/parsers/o3d_parser.py`: header, colisión, huesos base,
  objetos (SKIN/NORMAL ± bump), índices, physique, materiales,
  bloques y animaciones embebidas → JSON (geometría opcional).
- `scripts/converters/o3d_to_glb.py`: escritor GLB sin dependencias
  (posiciones, normales, UV, índices, joints/weights, materiales con
  nombre de textura en extras).
- Verificación: batch sobre los 6202 `.o3d` con cuadre exacto de bytes
  e importación en Godot sin errores + captura de 3 modelos.
- `docs/o3d-research.md` actualizado a cuerpo resuelto.

## Capabilities

### New Capabilities

- `o3dflyff`: parser `.o3d` completo y conversor a `.glb`.

### Modified Capabilities

- (ninguna)

## Impact

- Solo `scripts/` + `docs/`; el juego sigue con placeholders (la
  sustitución visual es Fase 5).
- `.glb` generados no se versionan (derivables por cada dev).
