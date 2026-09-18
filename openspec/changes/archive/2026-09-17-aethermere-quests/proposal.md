## Why

El MVP pide 10 misiones y hay 2: el arco termina en cuanto empieza y el
jugador se queda sin dirección al nivel 2. Esta propuesta completa la
cadena 103 → 110 (fuegos fatuos, cuervos, lobos, alfa final) hasta el
nivel 5, repartida entre Maren y Pell para que ambos NPCs importen.

## What Changes

- `quests.json`: 8 misiones nuevas encadenadas (103 → ... → 110), todas
  `kill` con monstruos existentes; recompensas EXP + consumibles/trofeos.
- `npcs.json`: Maren ofrece 103/104/107/108/110, Pell 105/106/109.
- `dialogues.json`: nodo genérico `quest_board` ("¿Qué trabajo queda?")
  en ambos diálogos; Aceptar funciona ahí además de en `quest_offer`.
- Simulación: recorre la cadena 103 → 110, verifica recompensas y
  exige nivel ≥ 5 y 10/10 completadas.

## Capabilities

### New Capabilities

- (ninguna)

### Modified Capabilities

- `game-data`: contenido inicial pasa de 2 a 10 misiones encadenadas.
- `gameplay`: la simulación cubre la cadena completa hasta nivel 5.

## Impact

- Sin cambios de código salvo sim + Aceptar en `quest_board`; el
  `quest_manager` ya es genérico.
- Curva: ~1490 EXP de recompensas 103–110 + caza real → nivel 5–6.
