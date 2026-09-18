## Why

El juego solo corre en máquinas con Godot y cliente extraído: nadie
puede verlo sin ese setup. Un build web en GitHub Pages lo hace
jugable con un enlace, y sirve de demo pública del pipeline completo
(parsers → datos → Godot).

## What Changes

- `scripts/build_web.py`: prepara `data/` dentro del proyecto,
  genera `export_presets.cfg` (Web, `thread_support=false` para hosts
  estáticos), exporta a `web-dist/` y limpia.
- Deploy de `web-dist/` a la rama `gh-pages` (solo build, con `.nojekyll`).
- README con cómo jugar en web y cómo regenerar el build.

## Capabilities

### New Capabilities

- `webbuild`: build web reproducible + deploy a Pages.

### Modified Capabilities

- (ninguna)

## Impact

- `web-dist/` y `export_presets.cfg` gitignorados; `gh-pages` solo
  contiene artefactos.
- Sin cambios en el juego (el save usa IndexedDB en web sin código extra).
