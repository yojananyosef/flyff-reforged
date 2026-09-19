## Why

Ironhold es una "walled town" según el lore, pero el campamento es un
descampado: las casas pintadas solo existen en la textura del suelo.
El cliente trae 97 estructuras `Ctrl_*` + tiendas `Obj_*` con texturas
sueltas, y `o3d_to_glb.py` ya convierte estáticos (sin texturas: "se
convertirán en Fase 5"). Toca levantar el campamento sin parsear la
cola opaca del `.lnd`: unas pocas piezas fijas alrededor del spawn con
colisión.

## What Changes

- `scripts/converters/o3d_to_glb.py`: flag `--tex-dir` (mismo patrón
  que `o3d_to_skinglb.py`: lookup insensible a mayúsculas, embebe
  `images`/`samplers`/`textures` + `baseColorTexture`; aviso + blanco
  si falta).
- `scripts/converters/setup_props.py` (nuevo): lista fija
  (`Obj_EliunTent01/02`, `Obj_BeheBasicwall01`), resuelve `.dds`
  sueltos de `Model/Texture/`, convierte a PNG temporal y genera los
  `.glb` (no versionados).
- `data/zones.json`: `ironhold` gana `props`: `[{model, x, z, yaw}]`.
- `godot_project/scripts/main.gd`: `_load_props()` instancia cada
  `.glb` con snap a `ground_height` + colisión trimesh estática;
  sin archivos SHALL arrancar igual (repliegue).
- Fuera de alcance: parsear la cola del `.lnd`, puertas/teleports,
  interiores, NPC dentro de tiendas.

## Capabilities

### New Capabilities

- `props`: estructuras estáticas del campamento con colisión.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/` + `data/zones.json` + `main.gd` (+ `.glb` no
  versionados). Sin cambios en combate, misiones ni guardado.
