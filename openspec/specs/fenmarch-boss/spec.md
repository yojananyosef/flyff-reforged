## Purpose

El ridge de Fenmarch culmina en un alpha verdadero que cierra la progresión 4–8 con una caza final exigente y recompensada.

## Requirements

### Requirement: Boss de Fenmarch jugable

El juego SHALL generar en `fenmarch` un boss de nivel 8 con HP y ataque superiores a cualquier monstruo previo de la zona, visible y atacable en su área, otorgando EXP alta y desbloqueando el cierre cuando muere por daño del jugador.

#### Scenario: Caza del boss

- **WHEN** el jugador con la 206 activa derrota al boss de Fenmarch
- **THEN** recibe la recompensa final y la cadena de Fenmarch queda completada sin quests pendientes

#### Scenario: Curva 4–8 completa

- **WHEN** se recorre `fenmarch` con nivel 4–8
- **THEN** existen monstruos propios de niveles 4, 5, 6, 7 y boss 8 con stats crecientes y EXP acorde

### Requirement: Quest 206 de cierre

La quest 206 SHALL requerir la 205, pedirla al warden de Fenmarch y contar la muerte del boss; al completarla SHALL otorgar la recompensa final (650 EXP + espada Alpha + colmillos) y no desbloquear más quests de Fenmarch.

#### Scenario: Cierre 205 → 206

- **WHEN** se completa la 205 y se habla con el warden de Fenmarch
- **THEN** la 206 está disponible, y al matar al boss se completa y la cadena queda cerrada
