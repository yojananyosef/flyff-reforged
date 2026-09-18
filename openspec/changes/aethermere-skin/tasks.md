## 1. Exportador

- [x] 1.1 `o3d_to_skinglb.py` (esqueleto + skin + animaciones) y Rangda+atk1 importa sin errores, verificado bind pose sana en captura
- [x] 1.2 Animación atk1 en 3 frames sin explosión y con flexión visible, verificado en capturas

## 2. Integración

- [x] 2.1 `model` en `monsters.json` (5 criaturas view-verificadas) + validador, `validate_data.py` pasando
- [x] 2.2 `setup_models.py` genera 5 `.glb` en `godot_project/models/`, verificado 5/5
- [x] 2.3 Monstruos con modelo (stand loop, die al morir, repliegue a cápsula), verificado en captura del juego y sim PASS

## 3. Cierre

- [x] 3.1 `openspec validate aethermere-skin --strict` pasa sin errores
- [x] 3.2 Commit + push y repo remoto actualizado
