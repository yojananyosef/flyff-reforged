## 1. Reverse engineering

- [ ] 1.1 Volcado de cabecera + búsqueda de rachas f32 + prueba de dimensiones; layout fijado
- [ ] 1.2 `lnd_parser.py` (header + alturas + encaje) con batch 900/900 y continuidad de bordes

## 2. Conversión e integración

- [ ] 2.1 `lnd_to_glb.py` + `setup_terrain.py` (tiles del área de juego) verificados en proyecto scratch
- [ ] 2.2 Sustitución del Ground con repliegue al plano; spawn asentado; `docs/lnd-research.md`

## 3. Verificación y cierre

- [ ] 3.1 Captura in-game con relieve + SIM-QUEST PASS + prueba en navegador
- [ ] 3.2 `openspec validate aethermere-lnd --strict` OK
- [ ] 3.3 Commit + push (+ rebuild web si afecta al .pck)
