## Context

Specs estables: `skin` (exportador skinned+animado), `anim`,
`player-avatar` (montaje con repliegue). Evidencia: `o3d_to_skinglb.py`
guarda `extras.flyff_texture` por material y UVs 0..1 (verificado en
`PlayerMvr.glb`); `lnd_to_glb.py` ya embebe PNG como
`images`/`samplers`/`textures` (patrón a reutilizar). Cliente en
`~/Downloads/Flyff_US_extracted`. Texturas: monstruos + cabeza del
jugador sueltos en `Model/Texture/`; piezas del vagabundo en
`Model/Texture/part_mTex.res` (vía `res_parser.py`, formato resuelto en
`terrain-color`); PIL lee DDS (precedente `setup_terrain.py`).

## Goals / Non-Goals

**Goals:**

- 6 `.glb` (jugador + 5 monstruos) con pintura embebida, repliegue a
  blanco sin PNGs, SIM-QUEST PASS + captura en navegador.
- Un solo script que deriva todo desde el cliente (`setup_model_textures.py`).

**Non-Goals:**

- Equipo intercambiable, normales/specular, texturas de NPC.
- Cambios en `godot_project/scripts/` (el material llega en el `.glb`).

## Decisions

- **Embeber en el `.glb` en vez de asignar en runtime**: reutiliza el
  patrón de `lnd_to_glb.py`; Godot importa `baseColorTexture`
  directamente y no hay que resolver nombres en el juego. Los `.glb` no
  se versionan, así que el peso extra no contamina el repo.
- **Lookup insensible a mayúsculas por nombre base**: el cliente mezcla
  `.dds`/`.DDS` y los materiales traen el nombre exacto; se normaliza a
  minúsculas al buscar `<base>.png` en `--tex-dir`.
- **RGBA sin recompresión**: se conserva el alfa del DDS (pelos y
  bordes lo usan); Godot genera los `.import` como hoy.
- **UVs tal cual**: rango 0..1 verificado; D3D y glTF comparten origen
  arriba-izquierda, sin voltear (si la captura muestra espejo vertical
  se ajusta con `flip_v` en el conversor).
- **setup_model_textures.py orquesta, no duplica**: extrae (sueltos +
  `.res`), convierte a PNG temporal y llama a `setup_models.py` y
  `setup_player_model.py` con `--tex-dir`; estos solo propagan el flag.

## Risks / Trade-offs

- [Riesgo] V invertida en alguna pieza → Mitigación: captura en
  navegador del avatar de frente y de un monstruo antes de cerrar.
- [Riesgo] Textura ausente (nombre no encontrado) → Mitigación:
  aviso por pieza + blanco como hoy (repliegue por pieza).
- [Riesgo] PIL sin DDS en algún dev → Mitigación: error claro; el
  juego sigue con `.glb` sin texturas.

## Migration Plan

No aplica. Rollback = regenerar `.glb` sin `--tex-dir` (repliegue).

## Open Questions

- Ninguna bloqueante.
