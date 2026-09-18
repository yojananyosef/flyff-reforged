# Design: aethermere-spawn-safe

## Protección (`player.gd` + `monster.gd` + `hud.gd`)

- `player.protect_t: float`, `PROTECT_MAX = 6.0`. Se pone a 6 en `_ready` y
  `_respawn`; tick `protect_t = maxf(0, -delta)` en `_physics_process`.
  `attack()` y `cast_skill()` (al validar estado, antes de efectos) lo ponen
  a 0 — moverse y fijar objetivo con clic NO lo rompen (solo dañar).
- `take_mob_damage`: `if protect_t > 0: return` al inicio.
- `monster._update_aggro`: si el jugador está protegido, suelta agro y no
  fija (`player.get("protect_t", 0.0)`; el jugador siempre lo expone).
- Bloque de contacto: si protegido, ni agro, ni anim, ni daño.
- HUD: label `PROTEGIDO (%.0fs)` bajo la cruz (código, como la cruz);
  visible solo si `protect_t > 0`.

## Build tag (`build_web.py` + `game_data.gd` + `hud.gd`)

- `build_web.py`, tras copiar `data/` al staging: escribe
  `data/build.json` con `{"tag": "<short> <YYYY-MM-DD>"}` del `HEAD`
  (`git rev-parse --short HEAD`; si falla, `local`). Se limpia con el resto
  del staging; nunca se versiona.
- `game_data.gd`: intenta cargar `res://data/build.json` en `_ready`;
  `build_tag()` devuelve `tag` o `"dev"`.
- HUD: label abajo-derecha con `"build " + tag`, font 12, visible siempre.

## Verificación

- Sim PASS: 3 aserciones (inmunidad, sin agro, ruptura) + `protect_t = 0`
  explícito donde el sim necesita combate (bloque agro en adelante).
- Navegador: spawn con `PROTEGIDO` visible y HP 100 tras 6 s quieto con el
  lobo al lado; tag igual al commit desplegado.
