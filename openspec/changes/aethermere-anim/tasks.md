## 1. Locomoción

- [x] 1.1 `monster.gd`: `walk`/`Walk` en bucle al vagar + yaw hacia `_dir`; repliegue a `stand` si no hay clip
- [x] 1.2 Facing también al cambiar de dirección (`_pick_direction`), sin giros bruscos (lerp)

## 2. Ataque

- [x] 2.1 `monster.gd`: `atk1`/`atk2`/`att1`/`att2` una vez al aplicar daño por contacto, luego vuelta a `walk`; sin clip no hay animación pero el daño se mantiene
- [x] 2.2 `_die` manda sobre ataque en curso (guardia `_dead` tras el `await`)

## 3. Verificación y cierre

- [x] 3.1 Sim `--sim-quest`: aserciones walk (4/5 con clip) + atk al golpear (loro exento documentado), PASS sin regresiones
- [x] 3.2 Captura del juego con monstruos en marcha + `openspec validate aethermere-anim --strict` OK
- [x] 3.3 Commit + push (+ rebuild web si el cambio afecta al .pck)
