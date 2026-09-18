## 1. Exportador multi-pieza

- [x] 1.1 `o3d_to_skinglb.py` acepta `--o3d` repetible y fusiona las mallas en un solo `.glb` (mismo skin/skeleton); el caso de un `.o3d` sigue idéntico
- [x] 1.2 `setup_player_model.py` (chr `mvr_male` + 5 piezas + 3 anis renombradas a stand/walk/atk1 → `PlayerMvr.glb`) verificado contra el cliente

## 2. Integración en el juego

- [x] 2.1 `player.gd` monta `PlayerMvr.glb` con repliegue (stand/walk/atk1; cápsula + punch si no hay modelo) sin tocar colisión ni lógica
- [x] 2.2 Sim en `main.gd`: checks de avatar montado y locomoción activa

## 3. Verificación y cierre

- [x] 3.1 Captura in-game del avatar + SIM-QUEST PASS + prueba en navegador
- [x] 3.2 `openspec validate aethermere-player-avatar --strict` OK
- [ ] 3.3 Commit + push (+ rebuild web si afecta al .pck)
