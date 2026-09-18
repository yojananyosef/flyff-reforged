## 1. Exportador multi-pieza

- [x] 1.1 `o3d_to_skinglb.py` acepta `--o3d` repetible y fusiona las mallas en un solo `.glb` (mismo skin/skeleton); el caso de un `.o3d` sigue idéntico
- [x] 1.2 `setup_player_model.py` (chr `mvr_male` + 5 piezas + 3 anis renombradas a stand/walk/atk1 → `PlayerMvr.glb`) verificado contra el cliente

## 2. Integración en el juego

- [x] 2.1 `player.gd` monta `PlayerMvr.glb` con repliegue (stand/walk/atk1; cápsula + punch si no hay modelo) sin tocar colisión ni lógica
- [x] 2.2 Sim en `main.gd`: checks de avatar montado y locomoción activa

## 3. Revisión: postura de zombi, marcha invisible y encarado

- [x] 3.1 Conjugado de cuaterniones en `o3d_to_skinglb.py` (giros espejados); clips con cuerpo completo (`AtkStand-15`, `AtkWalk-15`)
- [x] 3.2 `player.gd` encara a la víctima al golpear (+ check en el sim)
- [x] 3.3 SIM-QUEST PASS + capturas en navegador (reposo, marcha, ataque) + `validate --strict`
- [x] 3.4 Commit + push + rebuild web y deploy a gh-pages

## 4. Segunda revisión (causas reales)

- [x] 4.1 Clips `-15`/`-13` de marcha son posturas de montura (torso plegado) → `GenRun` erguido con zancada
- [x] 4.2 Quats sin conjugar (conjugando se niegan las flexiones); horneado de huesos estáticos con su TM del `.ani`
- [x] 4.3 Verificación: sim + capturas (reposo natural, carrera erguida, ataque encarado)
