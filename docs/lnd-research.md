# Investigación del formato .lnd (terreno FlyFF v21)

Estado: **resuelto y verificado** — parser (`scripts/parsers/lnd_parser.py`),
conversor (`scripts/converters/lnd_to_glb.py`) y setup
(`scripts/converters/setup_terrain.py`). Batch: **900/900 tiles de
WdMadrigal parsean**, coordenadas de cabecera cuadran con el nombre.

## Layout (verificado)

```text
u32 version        # = 3
u32 tile_x, tile_y # coinciden con WdMadrigalXX-YY.lnd
f32[129*129]       # alturas en metros, byte 12 (66564 B), filas N->S
...                # cola variable: capas/objetos (SIN parsear)
```

- Rejilla 129×129 confirmada por continuidad exacta de bordes (E-W 0.0 en
  plano y montaña) y por mínima discontinuidad vertical (stride 129 gana).
- `3000.0` (y picos > 2000) = vacío/fuera del mapa; `~100.0` = nivel del
  mar (oeste: océano); tierra jugable ~20–1500 m.
- Madrigal: 30×30 tiles. Oeste = mar plano; este (x13–18, y04–08) =
  montañas hasta ~1300 m; costa suave en x09–12, y16–18.

## Decisiones de integración

- Tamaño de tile **128 m** (flag `--tile-size`): con alturas en metros da
  pendientes naturales a escala del jugador (1.6 m). Supuesto documentado,
  no verificado contra el cliente.
- Vacío: **relleno por difusión** desde vecinos (sin muros de 100 m);
  reductos aislados a nivel del mar. Rebase **−100** (mar → y=0).
- Área de juego: bloque 2×2 **x10–11/y16–17** (costa suave, 0 % vacío en
  la fila sur), centro del tile (10,17) en el origen del juego.
- Colisión `HeightMapShape3D` + snap de NPC/spawn/monstruos por bilineal;
  visual `.glb` con repliegue a malla en código si no está importado, y al
  plano si no hay archivos generados.

## Cola del tile (pendiente, fuera del MVP)

Tras la rejilla: records mixtos (f32 de alturas sueltas ~200–360 =
¿agua/objetos?), bloques de 16384 words (¿capas 128×128?) y rachas
`f×1/0×15`. Los `.res` gemelos van XOR-ofuscados (otra tarea).
