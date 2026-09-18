## Purpose

Ajustes al slice jugable exigidos por el sistema de skills.

## MODIFIED Requirements

### Requirement: Combate placeholder

Los monstruos SHALL generarse desde `monsters.json` (5×`mon_001` + 1 de
cada otro tipo de `ironhold`), deambular, recibir daño del ataque melee
del jugador (clic, 2.5 m, fórmula física con poder 0) y de Ember Slash
(tecla 1, alcance 3.0 m), morir otorgando EXP/drops, y dañar por contacto
con la fórmula física contra la defensa del jugador.

#### Scenario: Cazar una liebre

- **WHEN** el jugador golpea a `mon_001` hasta agotar su HP
- **THEN** el monstruo muere, el jugador recibe 8 EXP y el progreso de
  `quest_101` aumenta en 1
