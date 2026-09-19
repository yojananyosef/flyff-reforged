## Context

Specs estables: `terrain` (rejilla 129×129, malla+HeightMap, snap,
repliegue). Evidencia en `docs/lnd-research.md`. Cliente en
`~/Downloads/Flyff_US_extracted`. Formato `.res` resuelto con
`Francesco149/flyfftools` (`flyffres.c`): cabecera key+crypt+hdrsize,
cifrado `~b ^ key` + swap de nibbles, tabla de ficheros.

## Goals / Non-Goals

**Goals:**

- Atlas 2×2 con las 4 texturas del área, UV por tile continuas.
- Agua visible en océano/costa, hierba/árboles sobre verde pintado.
- Repliegue total sin archivos generados; SIM-QUEST PASS + capturas.

**Non-Goals:**

- Cola del `.lnd` (capas/alpha): sigue opaca; el atlas por tile la
  sustituye visualmente.
- Objetos 3D (casas, muros): la pintura ya los dibuja; instanciarlos
  requiere la cola opaca.
- Texturas de personajes; sway de hierba por shader.

## Decisions

- **Atlas único 512×512 en vez de 4 materiales**: un solo draw, UV por
  cuadrante con inset de medio téxel contra el sangrado. El writer
  mínimo de `lnd_to_glb.py` se extiende con `images`/`samplers`/
  `textures` (PNG embebido, `mimeType` + `bufferView`).
- **Puestos horneados en setup (no en Godot)**: clasificar verde en
  Python con PIL (determinista, semilla fija) y guardar la lista en el
  JSON; Godot solo instancia MultiMesh (hierba: quads cruzados;
  árboles: cono+tronco). Criterio: sobre el mar y pendiente suave.
- **Agua como quad gigante en y≈0.05 con transparencia**: el depth
  test la oculta bajo el relieve emergido; sin geometría recortada.
- **Fallback conserva verde plano**: devs sin cliente ven lo mismo que
  hoy más el agua si hay JSON.

## Risks / Trade-offs

- [Riesgo] Orientación N-S de la textura al revés → Mitigación: el
  atlas cose continuo sin voltear; captura de verificación costa vs
  relieve antes de cerrar.
- [Riesgo] Sangrado entre cuadrantes con filtrado → Mitigación: inset
  de medio téxel + captura de bordes.
- [Riesgo] PIL sin DDS en algún dev → Mitigación: error claro en
  setup_terrain; el juego repliega sin atlas.

## Migration Plan

No aplica. Rollback = borrar generados (repliegue).

## Open Questions

- ¿La cola del `.lnd` trae alphas por capa? Pendiente para otro change;
  no bloquea este.
