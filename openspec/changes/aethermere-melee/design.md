# Design: aethermere-melee

## Monstruo: frenar + encarar (`monster.gd`)

- Parada: con agro, si `dist < 1.1` → `_dir = Vector3.ZERO`, `speed = 0`
  (mantiene facing y el ataque por contacto a < 1.4 m sigue disparando).
  Sin agro, deambular como hoy. Esto elimina el empuje bajo la cápsula del
  jugador (el "salto" fantasma).
- Snap: en el bloque de contacto, antes de `_try_attack_anim()`:
  `rotation.y = atan2(to_player.x, to_player.z)`. El lerp de marcha se
  conserva; el golpe siempre mira al jugador aunque el lerp llegara tarde.
- Colisión: monstruos en capa 2 / máscara 1 (`main.gd`): el jugador los
  atraviesa (con agro en enjambre lo encerraban y no podía caminar); el
  contacto sigue por distancia y el monstruo frena a 1.1 m.

## Jugador: clic-mover + auto-básicos (`player.gd`)

- Estado: `move_dest: Vector3` + `has_dest: bool`, `auto_attack := false`,
  `basic_cd`, `BASIC_CD_MAX = 0.9`, marcador `MoveMarker` (TorusMesh plano
  amarillo, hijo de la escena raíz, oculto por defecto).
- Clic (capturado): un solo rayo central (`_click_hit()` devuelve dic con
  `monster` y/o `ground`):
  - monstruo → `target` (+ `attack(monstruo)` como hoy);
  - si no, suelo (normal.y > 0.5, dentro de ±19 m) → `move_dest`,
    `auto_attack = false`, marcador visible;
  - si no, `attack()` clásico.
- Doble clic (`mb.double_click`) a monstruo → `target` + `auto_attack = true`
  (el movimiento lo acerca; al llegar, `attack()` respeta el cooldown).
- `_physics_process`: si hay `input_dir` WASD → manda teclado y limpia
  `has_dest` (el auto-ataque persiste pero no empuja mientras hay teclas).
  Si no hay teclas: destino → dir al punto (llega a < 0.4 → limpia); si no,
  auto-ataque con objetivo válido → dir al objetivo hasta `attack_range *
  0.9`, y `attack()` cuando está en rango (el cooldown lo ritma).
- `attack()`: si `basic_cd > 0` → `false` sin efectos; al impactar,
  `basic_cd = 0.9` + punch de escala en `body_mesh` (tween 0.18 s, se mata
  el anterior si sigue vivo).
- Limpieza: `target`/destino/auto se limpian en `_respawn`; objetivo
  inválido → null (vigente) y apaga el auto.

## Verificación

- Sim: 6 aserciones (frenada, encarado, click-mover, WASD cancela,
  auto-básicos, cooldown) + PASS sin regresiones.
- Navegador: clic al suelo → anillo + desplazamiento; doble clic a bicho →
  persecución y HP bajando; 0 errores.
