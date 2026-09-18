## Why

El live es injugable al aparecer: un lobo (agro 8 m) y el jabalí convergen
al spawn y matan al nivel 1 en ~30 s sin que toque nada (6 muertes en 90 s
en la prueba con navegador, sin jugar). Desde el jugador se siente como
"nada funciona". Además, cuando algo falla no hay forma de saber qué build
corre en el navegador (caché mediante).

## What Changes

- `player.gd`: `protect_t = 6.0` al aparecer/resucitar; tick en física; lo
  rompe atacar o castear (huir andando lo conserva). `take_mob_damage` no
  hace nada mientras dure.
- `monster.gd`: el agro ignora (y suelta) al jugador protegido; el bloque
  de contacto lo salta (sin daño ni anim de ataque).
- `hud.gd`: etiqueta `PROTEGIDO (Xs)` bajo la cruz mientras dure.
- `build_web.py` + `game_data.gd` + `hud.gd`: el build escribe
  `data/build.json` (solo staging, no se versiona) con tag corto del commit;
  el HUD lo muestra abajo a la derecha (`build xyz`, `dev` en local).
- Sim: el daño se ignora protegido, el agro no se fija protegido, atacar lo
  rompe. El sim pone `protect_t = 0` donde necesita combate real.

## Capabilities

### New Capabilities

- `spawnsafe`: protección temporal al aparecer con ruptura al atacar.
- `buildtag`: etiqueta visible del build desplegado.

### Modified Capabilities

(none)

## Impact

- `player.gd`, `monster.gd`, `hud.gd`, `game_data.gd`, `build_web.py`, sim.
- Sin cambios en daño, agro fuera de protección ni datos versionados.
