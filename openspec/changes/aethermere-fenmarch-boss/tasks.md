## 1. Datos de Fenmarch

- [x] 1.1 `monsters.json` 010–012 + `zones.json` fenmarch.monsters + `npcs.json` npc_003 ofrece 206 y verificar con `validate_data.py`
- [x] 1.2 `quests.json` 205 desbloquea 206 + 206 (boss 1×mon_012, 650 EXP) y verificar cadena 201–206 sin huecos
- [x] 1.3 `dialogues.json` nodo boss en Sella y verificar texto visible en panel

## 2. Sim y verificación

- [x] 2.1 `main.gd` SIM-QUEST cubre 201–206 + boss (aceptar, kills, recompensa, cierre) y verificar `SIM-QUEST PASS` sin regresiones
- [x] 2.2 `openspec validate aethermere-fenmarch-boss --strict` OK y captura en navegador del boss
