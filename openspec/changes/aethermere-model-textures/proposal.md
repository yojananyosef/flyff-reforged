## Why

Jugador y monstruos se ven en gris/blanco liso: el exportador
`o3d_to_skinglb.py` vuelca la malla con `baseColorFactor` blanco y guarda
el nombre de la textura FlyFF solo en `extras.flyff_texture`, sin
embebarla. El cliente trae las texturas reales (`.dds` sueltos en
`Model/Texture/` para monstruos y cabeza del jugador; `part_mTex.res`
para el resto del vagabundo; PIL ya lee DDS como en
`setup_terrain.py`). Toca vestir los modelos con lo suyo.

## What Changes

- `scripts/converters/o3d_to_skinglb.py`: flag `--tex-dir` con PNGs
  preparados; por cada material busca `<flyff_texture sin extensión>.png`
  (insensible a mayúsculas) y embebe `images`/`samplers`/`textures` +
  `baseColorTexture` (TEXCOORD_0, ya presente). Sin PNG SHALL mantener
  el blanco actual.
- `scripts/converters/setup_model_textures.py` (nuevo): resuelve las
  texturas de jugador + monstruos (sueltos de `Model/Texture/` y
  `part_mTex.res` vía `res_parser`), las convierte a PNG (PIL, RGBA) en
  un dir temporal y re-ejecuta `setup_models.py` + `setup_player_model.py`
  con `--tex-dir`.
- `setup_models.py` / `setup_player_model.py`: aceptan y propagan
  `--tex-dir` a `o3d_to_skinglb.py`.
- Fuera de alcance: ropa/equipo intercambiable, normales/specular,
  texturas de NPC y de terreno (ya cubierto por `terrain-color`).

## Capabilities

### New Capabilities

- `skin-texture`: texturas reales embebidas en personajes.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/` + `.glb` regenerados (no versionados, derivables por
  cada dev con PIL). Sin cambios en `godot_project/scripts/`, datos ni
  gameplay: el material pintado llega por el propio `.glb`.
