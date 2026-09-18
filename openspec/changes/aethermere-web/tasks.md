## 1. Build

- [ ] 1.1 `scripts/build_web.py` (stage + preset nothreads + export + limpieza), verificado log usa `web_nothreads_release` y salen html/js/wasm/pck
- [ ] 1.2 El build local sirve por HTTP (200 en `/` y `.pck`) y el juego carga datos empaquetados, verificado sin errores de export

## 2. Deploy y docs

- [ ] 2.1 Rama `gh-pages` con el build + `.nojekyll`, pusheada al remoto
- [ ] 2.2 README con enlace, controles y cómo regenerar; `openspec validate` OK; commit + push en `main`
