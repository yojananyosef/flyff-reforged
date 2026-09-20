## 1. Contratos repetibles

- [x] 1.1 `quests.json` 207–209 (`repeatable`, requieren 206, sin unlocks) + `quest_manager.gd` omite `done` si repetible y verificar reoferta tras completar
- [x] 1.2 SIM-QUEST acepta/completa/repite la 207 con recompensa y verificar PASS sin regresiones

## 2. Mercader y crecimiento

- [x] 2.1 `npcs.json` npc_004 + `dialogues.json` mercader + `zones.json` Fenmarch y verificar Sella + mercader visibles con Comerciar
- [x] 2.2 `player.gd` +12 HP/+4 MP por nivel y verificar números + sim intacto

## 3. Equipo visible

- [x] 3.1 `player.gd` props por tier (`GearBlade` + hombreras, color/tamaño, ocultar al desequipar) y verificar en sim por tier
- [x] 3.2 `openspec validate aethermere-endgame-depth --strict` OK + rebuild web
