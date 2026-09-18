## 1. Parser

- [x] 1.1 `o3d_parser.py` con header, colisión, huesos, objetos, materiales y animaciones, verificado en 3 modelos representativos con cuadre exacto
- [x] 1.2 Batch sobre los 6202 `.o3d`: ≥98% cuadre exacto de bytes e índices en rango, resto listados con motivo

## 2. Conversor

- [x] 2.1 `o3d_to_glb.py` (pos/normal/uv/índices/skin/materiales) y Godot importa 3 modelos sin errores, verificado con `--import` en proyecto scratch
- [x] 2.2 Captura con los 3 modelos instanciados, verificado que se ven como geometría coherente (no sopa de triángulos)

## 3. Cierre

- [x] 3.1 `docs/o3d-research.md` actualizado a cuerpo resuelto
- [x] 3.2 `openspec validate aethermere-o3d --strict` pasa sin errores
- [x] 3.3 Commit + push y repo remoto actualizado
