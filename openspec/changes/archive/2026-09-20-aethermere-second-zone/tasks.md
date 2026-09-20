## 1. Terreno y datos de Fenmarch

- [x] 1.1 `setup_terrain.py --tiles/--center/--name` (defecto
  Ironhold) + generar `terrain_fenmarch.*` y elegir spawn/props en
  llano (+ `VOID_EXACT {1000.0}`: el cliente rellena sin diseñar)
- [x] 1.2 `zones.json`: `fenmarch` (spawn, props, `travel` mutuo) +
  `x,z` en `npcs.json` + `npc_003`
- [x] 1.3 `monsters.json` 006–009 + `quests.json` 201–205 +
  `dialogues.json dlg_sella_intro` + `.glb` de Raundas

## 2. Motor multizona

- [x] 2.1 `main.gd`: terreno/props/NPC-slots por zona + portal
  visible + `E` para viajar (set zona + save + reload) +
  `_build_zone()` reutilizable + pista HUD por zona

## 3. Verificación y cierre

- [x] 3.1 SIM-QUEST PASS (160 + viaje ida/vuelta, spawn apoyado,
  201 aceptable y contable) + captura en navegador de Fenmarch
  (+ fix: el save manda la zona al arrancar; pista HUD por zona)
- [x] 3.2 `openspec validate aethermere-second-zone --strict` OK
- [x] 3.3 Commit + push (+ rebuild web y deploy a gh-pages)
