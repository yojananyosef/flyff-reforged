## Purpose

Primer slice jugable sobre la base Godot: diálogo con NPC, misiones
101 → 102, combate cuerpo a cuerpo contra placeholders y inventario,
todo alimentado por los JSON de `data/`.

## ADDED Requirements

### Requirement: Interacción y diálogo con NPC

El juego SHALL mostrar un NPC placeholder para `npc_001` que al pulsar E
en rango abre un panel con el nodo `start` de su diálogo, navega opciones
vía `next` y ofrece aceptar `quest_101` en el nodo `quest_offer`.

#### Scenario: Hablar con la Anciana Maren

- **WHEN** el jugador pulsa E junto al NPC
- **THEN** el panel muestra el texto del nodo `start` con sus 2 opciones, y
  navegar a `quest_offer` muestra el botón de aceptar misión

### Requirement: Gestión de misiones

El autoload `quest_manager` SHALL aceptar misiones, contar muertes del
objetivo, completar con recompensas (EXP + items) y desbloquear `quest_102`
al completar `quest_101`, ignorando aceptados repetidos.

#### Scenario: Flujo 101 → 102

- **WHEN** se acepta `quest_101` y se registran 5 muertes de `mon_001`
- **THEN** la misión queda completada, se otorgan 40 EXP + `item_003` y
  `quest_102` pasa a disponible

### Requirement: Tracker de misión en HUD

El HUD SHALL mostrar la misión activa con su progreso (`x/y` muertes) y
actualizarse al aceptar, progresar y completar.

#### Scenario: Progreso visible

- **WHEN** se acepta `quest_101`
- **THEN** el tracker muestra el título y `0/5` antes del primer frame
  visible siguiente

### Requirement: Combate placeholder

Los monstruos SHALL generarse desde `monsters.json` (5×`mon_001` + 1 de
cada otro tipo de `ironhold`), deambular, recibir daño del ataque melee
del jugador (clic, 2.5 m), morir otorgando EXP/drops, y dañar por contacto.

#### Scenario: Cazar una liebre

- **WHEN** el jugador golpea a `mon_001` hasta agotar su HP
- **THEN** el monstruo muere, el jugador recibe 8 EXP y el progreso de
  `quest_101` aumenta en 1

### Requirement: Inventario

El jugador SHALL tener inventario (items iniciales + drops) visible en un
panel con la tecla I, actualizado al recibir items.

#### Scenario: Loot visible

- **WHEN** un monstruo muere y suelta `item_005`
- **THEN** el inventario contiene 1 unidad más de `item_005` y el panel
  abierto lo refleja

### Requirement: Simulación headless de misión

El juego SHALL aceptar `--sim-quest`: corre aceptar → 5 muertes →
verificar recompensas y desbloqueo, imprime `SIM-QUEST PASS` (o FAIL) y
sale con código acorde.

#### Scenario: Verificación repetible

- **WHEN** se arranca `godot --headless res://scenes/main.tscn -- --sim-quest`
- **THEN** la salida contiene `SIM-QUEST PASS` y el proceso termina con
  código 0
