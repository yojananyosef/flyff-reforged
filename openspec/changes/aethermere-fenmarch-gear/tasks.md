## 1. Datos y tienda

- [x] 1.1 `items.json` 011–014 (tier Fenmarch con nivel/precio/bonus) y verificar con `validate_data.py`
- [x] 1.2 `quests.json` 202/204/206 premian equipo Ridge/Alpha y verificar cadena 201–206
- [x] 1.3 `hud.gd` `SHOP_STOCK` con los 8 artículos y verificar tienda abre con 8 y respeta nivel/oro

## 2. Sim y verificación

- [x] 2.1 `main.gd` SIM-QUEST cubre builds Ridge/Alpha + números de balance del boss y verificar `SIM-QUEST PASS` sin regresiones
- [x] 2.2 `openspec validate aethermere-fenmarch-gear --strict` OK + rebuild web
