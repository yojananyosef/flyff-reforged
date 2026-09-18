## 1. Monstruo: distancia + encarado

- [x] 1.1 Frenar a 1.1 m con agro (no empuja ni se mete debajo)
- [x] 1.2 Snap de yaw al jugador al aplicar golpe por contacto

## 2. Jugador: clic-mover + auto-básicos

- [x] 2.1 Rayo único (`_click_hit`): monstruo → target; suelo → `move_dest` + anillo; resto → ataque clásico; doble clic → `auto_attack`
- [x] 2.2 Marcha a destino (llega < 0.4 m), WASD cancela; auto-ataque acerca hasta rango y repite básicos
- [x] 2.3 Cooldown 0.9 s en `attack()` + punch de escala visible; limpieza en respawn

## 3. Verificación y cierre

- [x] 3.1 Sim PASS: 6 aserciones nuevas sin regresiones
- [x] 3.2 Navegador: anillo + marcha, doble clic con HP bajando, 0 errores
- [x] 3.3 Commit + push + rebuild web + deploy
