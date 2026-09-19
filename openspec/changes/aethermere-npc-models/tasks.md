## 1. Datos y generación

- [x] 1.1 `data/npcs.json`: `model` (`Mvr_NpcSebrance`, `mvr_NpcBato`)
- [x] 1.2 `setup_npcs.py`: `.glb` texturados vía `o3d_to_skinglb.py --tex-dir`

## 2. Montaje en escena

- [x] 2.1 `main.gd npc_setup()`: monta `.glb` si existe (oculta
  cápsula, idle en bucle, encara al spawn +PI); repliegue intacto
  (+ test de marcha en llano y recuento triple anti-flaky)

## 3. Verificación y cierre

- [x] 3.1 Captura en navegador (ambos NPC de frente, con ropa) +
  SIM-QUEST PASS (modelos montados, idle activo)
- [x] 3.2 `openspec validate aethermere-npc-models --strict` OK
- [ ] 3.3 Commit + push (+ rebuild web y deploy a gh-pages)
