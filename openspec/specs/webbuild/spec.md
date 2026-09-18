## Purpose

Hacer el juego jugable en navegador vía GitHub Pages con un build web
reproducible.

## Requirements

### Requirement: Build web reproducible

El script SHALL empaquetar datos + assets generados y exportar el
preset Web sin threads a `web-dist/` (html/js/wasm/pck), limpiando el
staging después.

#### Scenario: Export local

- **WHEN** se ejecuta `build_web.py --out web-dist`
- **THEN** el log muestra el template `web_nothreads_release`, existen
  los 4+ archivos y `web-dist/` no contiene `data/` suelta fuera del `.pck`

### Requirement: Deploy a Pages

La rama `gh-pages` SHALL contener solo el build + `.nojekyll` y el
README SHALL documentar enlace, activación y regeneración.

#### Scenario: Página servida

- **WHEN** se sirve `web-dist/` por HTTP estático
- **THEN** `/` responde 200 con el HTML del juego
