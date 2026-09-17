## 1. Diálogo interactivo

- [x] 1.1 NPC placeholder de la Anciana Maren en escena + interacción con E en rango y verificar que se abre el panel en el nodo `start`
- [x] 1.2 Panel navega opciones (`next`) de `dialogues.json` y botón Aceptar en `quest_offer` otorga `quest_101`, verificado headless/manual

## 2. Misiones

- [x] 2.1 Autoload `quest_manager` (aceptar, progreso, completar, recompensas, desbloqueo 101 → 102) y verificar que rechaza aceptados repetidos
- [x] 2.2 Tracker en HUD con misión activa y progreso `x/y`, verificado que muestra `quest_101 0/5` al aceptar
- [x] 2.3 Simulación `--sim-quest` en `main.gd` que corre el flujo completo y reporta `SIM-QUEST PASS`, verificado en headless

## 3. Combate placeholder

- [x] 3.1 Spawns desde `monsters.json` (5×`mon_001` + resto) con IA errante, HP y muerte, verificado conteo en arranque
- [x] 3.2 Ataque melee con clic (alcance 2.5 m) que daña/mata y otorga EXP, verificado que un golpe reduce HP del objetivo
- [x] 3.3 Daño por contacto al jugador y muerte con respawn en `spawn_point`, verificado sin atravesar el suelo

## 4. Inventario

- [x] 4.1 Inventario en jugador (items iniciales + drops de muertes) y panel con tecla I, verificado que un drop aparece en el panel

## 5. Cierre

- [x] 5.1 `openspec validate aethermere-gameplay --strict` pasa sin errores
- [x] 5.2 Commit + push y repo remoto actualizado
