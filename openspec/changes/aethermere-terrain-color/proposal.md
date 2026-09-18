## Why

Ironhold pisa relieve real pero todo es verde liso: el material es un
color plano y no hay agua ni vegetación. El cliente trae la pintura
real del suelo (texturas `WdMadrigal{XX}-{YY}.dds` por tile en los
`.res` gemelos `WdMadrigal_XX-YY.res`, formato resuelto con
`flyfftools`: XOR+nibble-swap) y las 4 del área cosen continuas sin
voltear (caminos y costa cruzan los bordes). Toca vestir el terreno con
lo suyo: atlas de texturas, agua al nivel del mar y hierba donde la
pintura muestra verde.

## What Changes

- `scripts/parsers/res_parser.py`: extracción de `.res` (cabecera
  key+crypt+hdrsize, descifrado `~b ^ key` + swap de nibbles, tabla
  nombre/tamaño/fecha/offset) verificada contra `wtex_m.res` y
  `WdMadrigal_10-15.res`.
- `scripts/converters/setup_terrain.py`: extrae los 4 `.dds` del área,
  los convierte a PNG (PIL) y cose un atlas 2×2
  (`terrain_ironhold_atlas.png`, no versionado); muestrea verde de la
  pintura y hornea puestos de hierba/árboles en el JSON (semilla fija,
  sobre el nivel del mar y en pendiente suave).
- `scripts/converters/lnd_to_glb.py`: UV por cuadrante de tile (inset
  de medio téxel) + material con la textura del atlas (imágenes y
  samplers glTF embebidos).
- `godot_project/scripts/main.gd`: plano de agua en y≈0 (transparente,
  solo visible donde el relieve baja), hierba/árboles por MultiMesh con
  repliegue (sin atlas: verde plano + agua como hoy… sin agua), y checks
  en el sim (textura en el material, agua presente, hierba instanciada).
- Fuera de alcance: la cola del `.lnd` (capas/alpha) sigue opaca y sin
  parsear; objetos 3D del `.res` (casas: la pintura ya las dibuja en el
  suelo); texturas de monstruos/jugador.

## Capabilities

### New Capabilities

- `terrain-color`: texturas reales por tile, agua y vegetación.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/` + `main.gd` + escena en arranque (agua/hierba con
  repliegue). Sin cambios en datos, colisión ni gameplay.
- `.glb`, atlas `.png` y puestos horneados no se versionan (derivables
  por cada dev con PIL instalado).
