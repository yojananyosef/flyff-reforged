## 1. Protección

- [x] 1.1 `player.gd`: `protect_t` 6 s en ready/respawn, tick, ruptura en `attack()`/`cast_skill()`, `take_mob_damage` la respeta
- [x] 1.2 `monster.gd`: agro y contacto ignoran a protegido
- [x] 1.3 HUD: etiqueta PROTEGIDO con cuenta atrás

## 2. Build tag

- [x] 2.1 `build_web.py` sella `data/build.json` en staging; `game_data.build_tag()`; HUD abajo-derecha

## 3. Verificación y cierre

- [x] 3.1 Sim PASS + 3 aserciones; `protect_t = 0` donde el sim combate
- [x] 3.2 Navegador: PROTEGIDO visible, HP intacto 6 s, tag = commit deploy
- [x] 3.3 Commit + push + rebuild + deploy
