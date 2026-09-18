## Why

El combate es un clic con daño fijo (14) y las 3 habilidades de
`skills.json` son texto muerto: el MP no se gasta ni se regenera y la
defensa de los monstruos no existe en la práctica. Esta propuesta
convierte los datos en sistema: stats, fórmula de daño, skills activas
con coste/cooldown y un buff defensivo.

## What Changes

- Stats en jugador (`base_attack`, `base_defense`) y fórmula global:
  `max(1, ataque + poder − defensa)`, con `Bulwark` reduciendo a la mitad.
- `cast_skill(id)`: Ember Slash (daño + alcance), Bulwark Stance (buff
  5 s), Field Bandage (cura 30%), con MP, nivel requerido y cooldowns.
- Barra de skills en HUD (1/2/3) con cooldown, bloqueo por nivel/MP e
  indicador de buff; regen de MP 3/s.
- SFX de cura (`ItemGnPotion.wav`, pasa a 17 archivos) y chequeos en sim.

## Capabilities

### New Capabilities

- `skills`: stats, fórmula de daño, skills activas y barra en HUD.

### Modified Capabilities

- `gameplay`: el ataque básico y el daño por contacto usan la fórmula;
  la simulación cubre las 3 skills.
- `audio`: +1 SFX (`heal`).

## Impact

- Sin cambios en `data/` (costes y poderes ya existen en `skills.json`).
- Rebalancea el grind de la 101 (básico 6/golpe a liebre, Ember 17).
