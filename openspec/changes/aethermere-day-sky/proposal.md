## Why

El cielo sale casi negro (`background_mode = 1` color 0.05/0.07/0.12
en `main.tscn`): de día el horizonte debería ser claro y cálido como
en las primeras capturas. Un `ProceduralSkyMaterial` barato (vale en
Compatibility/web) lo resuelve sin assets nuevos.

## What Changes

- `godot_project/scenes/main.tscn`: `sky_env` pasa a `background_mode
  = 2` (Sky) con `ProceduralSkyMaterial` diurno (cenit azul suave,
  horizonte crema cálido, sol acorde al `DirectionalLight3D`
  existente) + niebla estándar sutil para fundir las dunas.
- Fuera de alcance: ciclo día/noche, nubes, clima, estrellas.

## Capabilities

### New Capabilities

- `day-sky`: cielo diurno con niebla sutil.

### Modified Capabilities

(none)

## Impact

- Solo `main.tscn` (un sub-recurso + dos nodos sin script). Sin
  cambios en código, datos ni gameplay.
