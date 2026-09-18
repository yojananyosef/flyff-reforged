## Why

Ironhold flota sobre un plano verde perfecto de 40×40: es el marcador
visual más barato del juego. El cliente trae el terreno real
(`World/WdMadrigal/`, 900 tiles `XX-YY.lnd`, cuadrícula 30×30) y el
reconocimiento previo lo hace tratable: cabecera con versión + `3000.0`
repetidos, y clases de tamaño que difieren en múltiplos de ~133124 bytes
(2×~66562: capas del tile). Toca reverirlo como se hizo con `.o3d`
(empírico + cuadre en batch) y vestir la zona de juego.

## What Changes

- `scripts/parsers/lnd_parser.py`: cabecera, rejilla(s) de alturas y
  encaje de tiles → JSON; verificado en batch sobre los 900 tiles de
  WdMadrigal (100 % parsea, alturas sanas, continuidad de bordes muestreada
  y `docs/lnd-research.md` con el formato resuelto).
- `scripts/converters/lnd_to_glb.py`: malla de terreno (pos/normal/uv,
  material hierba simple) + `setup_terrain.py` para los tiles del área de
  juego (entorno del spawn).
- `godot_project`: el `Ground` plano se sustituye por la malla + colisión
  (trimesh) si existe `models/terrain_*.glb`; si no, plano como hoy
  (repliegue). El spawn cae por gravedad hasta el suelo.
- Fuera de alcance: texturas por capa, agua, objetos (`.res`), vegetación.

## Capabilities

### New Capabilities

- `terrain`: parser `.lnd`, conversor a `.glb` y suelo real en Ironhold.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/` + `docs/` + escena (sustitución del Ground con
  repliegue). Sin cambios en datos ni gameplay salvo la altura del suelo.
- Los `.glb` de terreno no se versionan (derivables por cada dev).
