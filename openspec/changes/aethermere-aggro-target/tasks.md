## 1. Agro en monster.gd

- [x] 1.1 `aggro_target` + `_update_aggro()`: proximidad 8 m, leash 14 m, congela rumbo aleatorio
- [x] 1.2 Persecución a 2.8 m/s hacia el jugador con facing; `take_damage(amount, from=null)` fija agro por daño; contacto fija agro

## 2. Target en player.gd + hud.gd

- [x] 2.1 `target`, `_pick_monster()` (rayo centro 100 m, excluye propio cuerpo), clic fija y golpea si hay rango; `attack(only=null) -> bool`
- [x] 2.2 Básico y Ember priorizan objetivo válido en rango; limpieza de objetivo inválido por frame
- [x] 2.3 HUD: cruz central + etiqueta `Objetivo: nombre HP/HP`; pista de controles en `main.tscn`

## 3. Verificación y cierre

- [x] 3.1 Sim `--sim-quest` PASS: 7 aserciones nuevas (agro×4, target×3) sin regresiones
- [x] 3.2 Navegador: clic fija objetivo visible en etiqueta + 0 errores consola
- [x] 3.3 Commit + push + rebuild web + deploy
