## 1. Formato .res y texturas

- [x] 1.1 `scripts/parsers/res_parser.py` (extracción `.res` con descifrado) + prueba contra `wtex_m.res` y `WdMadrigal_10-15.res`
- [x] 1.2 `setup_terrain.py` extrae los 4 `.dds`, los pasa a PNG y cose `terrain_ironhold_atlas.png`
- [x] 1.3 `lnd_to_glb.py` con UV por cuadrante + material con textura embebida (images/samplers)

## 2. Agua y vegetación

- [x] 2.1 `main.gd`: plano de agua en y≈0 con transparencia + repliegue
- [x] 2.2 Puestos de hierba/árboles horneados desde el verde pintado + MultiMesh en `main.gd` con repliegue
- [x] 2.3 Sim: checks de textura en material, agua presente y hierba instanciada

## 3. Verificación y cierre

- [x] 3.1 Capturas (suelo pintado continuo, costa con agua, hierba) + SIM-QUEST PASS + prueba en navegador
- [x] 3.2 `openspec validate aethermere-terrain-color --strict` OK
- [ ] 3.3 Commit + push (+ rebuild web y deploy a gh-pages)
