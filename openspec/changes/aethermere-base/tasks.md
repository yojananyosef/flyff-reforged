## 1. Parsers FlyFF

- [ ] 1.1 Implementar `scripts/parsers/chr_parser.py` (.chr → JSON) y verificar convirtiendo un `.chr` real del cliente con salida JSON válida
- [ ] 1.2 Implementar `scripts/parsers/ani_parser.py` (.ani → JSON) y verificar convirtiendo un `.ani` real del cliente con salida JSON válida
- [ ] 1.3 Implementar `scripts/parsers/extract_loose_files.py` y verificar copiando audio/texturas/modelos del cliente a `assets/` con resumen de conteos
- [ ] 1.4 Escribir `docs/o3d-research.md` con header conocido (XOR `0xCD`, versión, hash) y verificar que describe bytes resueltos vs pendientes

## 2. Datos del juego

- [ ] 2.1 Crear `data/items.json`, `monsters.json`, `skills.json` (10 items, 5 monstruos, 3 habilidades) y verificar que parsean como JSON válido
- [ ] 2.2 Crear `data/npcs.json`, `quests.json` (misión 101 → 102), `dialogues.json` (≥2 nodos) y verificar encadenamiento de misiones y nodos
- [ ] 2.3 Crear `data/zones.json` con `ironhold` → `WdMadrigal` y verificar campo `original_asset_dir` presente en cada zona
- [ ] 2.4 Implementar `scripts/generators/validate_data.py` (IDs únicos + referencias cruzadas) y verificar que falla con un ID roto de prueba y pasa con los datos reales

## 3. Base Godot

- [ ] 3.1 Crear `godot_project/project.godot` + escena principal que arranca sin errores y verificar arranque limpio en el editor
- [ ] 3.2 Implementar jugador 3ª persona (WASD + salto + cámara orbital con `SpringArm3D`) y verificar desplazamiento sin atravesar el suelo
- [ ] 3.3 Implementar HUD (barras HP/MP/EXP) enlazado a valores del jugador y verificar que un cambio de HP se refleja en la barra
- [ ] 3.4 Implementar carga de `zones.json`/`dialogues.json` al arranque y verificar que la zona actual queda registrada como `ironhold`

## 4. Cierre de fase

- [ ] 4.1 Ejecutar `openspec validate --change aethermere-base --strict` y verificar que pasa sin errores
- [ ] 4.2 Commit + push de la base y verificar repo remoto actualizado
