# Design: aethermere-aggro-target

## Agro (`monster.gd`)

Estado con una sola variable `aggro_target: Node3D` (null = deambular):

- `_update_aggro(player)`: si hay agro y el objetivo es inválido o está a
  > 14 m → soltar + `_pick_direction()`. Sin agro y jugador válido a
  < 8 m → fijar (suspende el rumbo aleatorio; el timer de paseo se congela).
- Con agro: `_dir` = hacia el jugador (XZ), `speed` = 2.8 (`CHASE_SPEED`);
  sin agro: rumbo aleatorio a 1.5 como hoy. El facing con lerp ya existe y
  sirve para ambos.
- `take_damage(amount, from = null)`: si `from` está en el grupo `player`,
  fija agro (compatible con las llamadas actuales del sim, que no pasan
  atacante). El daño por contacto también fija agro antes de aplicarlo.
- El ataque (`_try_attack_anim`), su cooldown y `_die` no cambian; `_die`
  limpia el agro.

Constantes: `AGGRO_RANGE = 6.0`, `LEASH_RANGE = 14.0`, `CHASE_SPEED = 2.8`.
6 m (no 8) para no convertir el spawn en enjambre instantáneo: varios
monstruos generan a 5–13 m del centro.
Sin riesgo de estampida: cada monstruo decide por distancia propia.

## Target (`player.gd` + `hud.gd`)

- `player.target: Node3D`. En clic izquierdo con ratón capturado:
  `_pick_monster()` → rayo desde el centro del viewport
  (`cam.project_ray_origin/Normal(size / 2)`, 100 m, excluyendo el propio
  cuerpo). Centro y no posición del clic: con pointer-lock la posición del
  evento no es fiable en web; el punto de mira central es predecible.
- Si hay impacto en grupo `monsters`: fijar + `attack(monstruo)` (golpea si
  está en rango; si no, fija igual y avisa). Sin impacto: `attack()` clásico.
- Tolerancia: si el rayo exacto no impacta (bichos pequeños en movimiento),
  se acepta el monstruo visible más cercano al punto de mira en 140 px.
- `attack(only = null) -> bool`: con `only` válido de grupo monstruos exige
  rango (si no, `false` + mensaje); sin `only`, el más cercano como hoy.
  `take_damage(dmg, self)` propaga atacante para el agro.
- `cast_skill("skill_001")`: usa el objetivo si válido y en rango; si no,
  el más cercano (whiff sin consumo, como hoy).
- Limpieza en `_physics_process`: `target` inválido → null.
- `hud.gd`: cruz `+` centrada (Label en código, como el debug) + etiqueta
  de objetivo sobre la barra de skills (`Objetivo: -` por defecto; con
  objetivo: `nombre HP/HP`). Sin toques a `main.tscn` salvo la pista de
  controles (`Clic fijar/atacar`).

## Verificación

- Sim: agro por proximidad (5 m → agro en ≤60 frames), caza (distancia
  mengua), agro por `take_damage(x, player)` fuera de rango, leash (>14 m
  suelta), prioridad de objetivo (pega al fijado a 2 m con otro a 1 m),
  fuera de rango no daña, limpieza al morir.
- Navegador: clic con monstruo al centro → etiqueta `Objetivo:` visible en
  captura; 0 errores de consola.
