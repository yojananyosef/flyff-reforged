# Design: aethermere-anim

## Contexto

`monster.gd` hoy: `_mount_model()` reproduce `stand` en bucle al aparecer y
`die*` una vez al morir (`_die`). `_physics_process()` deambula con `_dir`
aleatorio y aplica daño por contacto con `_touch_cooldown` de 1 s. Los 5
`.glb` ya contienen los clips (verificado por inspección del JSON):

- Buur, Dreamflame, Cat, Dog: `walk`, `atk1`, `atk2` (+ `stand`, `die1`…).
- Parrot (loro): solo `Idle1`, `Stand`, `Walk` — sin ataque ni muerte.

## Enfoque

Máquina mínima de 3 estados con el helper existente `_play_anim(cands, loop)`:

1. **wander**: al entrar (spawn y cada `_pick_direction`), `_play_anim(["walk",
   "Walk"], true)`; si falla, `_play_anim(["stand", "Stand", …], true)`.
   Orientación: `rotation.y = lerp_angle(rotation.y, atan2(_dir.x, _dir.z), …)`
   en `_physics_process` (el cuerpo del monstruo no tiene cámara hija, rotar
   el `CharacterBody3D` es seguro — a diferencia del jugador).
2. **attack**: en el golpe por contacto, si hay clip `atk*`, `_play_anim(
   ["atk1", "atk2", "att1", "att2", "Atk1"], false)` y, al terminar
   (`animation_finished` o espera acotada por frames como `_die`), volver a
   wander. El daño se aplica al inicio del golpe (sin cambios de balance).
   Sin clip, no se hace nada visual.
3. **dead**: sin cambios (`_die` vigente).

Concurrencia: si el monstruo recibe daño letal a mitad de `attack`, `_die`
manda (flag `_dead` + `set_physics_process(false)`); el `await` del ataque
comprueba `is_instance_valid` / `_dead` antes de restaurar `walk`.

## Alternativas descartadas

- Regenerar `.glb`: innecesario, los clips ya están dentro.
- `AnimationTree`/blend: sobredimensionado para 3 estados; `AnimationPlayer`
  directo como hoy.
- Retrasar el daño al impacto visual: cambiaría el balance y el sim; fuera
  de alcance.

## Verificación

- `godot --headless -- --sim-quest` PASS con 2 aserciones nuevas (walk en
  monstruos con modelo; atk al golpear salvo loro).
- Captura `--shot` + prueba en navegador (teclas no aplican a monstruos;
  verificación visual de marcha en captura del juego en marcha).
