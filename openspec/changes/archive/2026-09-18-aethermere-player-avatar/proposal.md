## Why

El jugador sigue siendo una cápsula azul lisa con un punch de escala como
gesto de ataque: es el marcador visual más barato del juego y sale en el
centro de cada captura. El pipeline skinned+animado ya funciona para
monstruos (`o3d_to_skinglb.py`, `setup_models.py`, montaje con repliegue
en `monster.gd`). El cuerpo del jugador va por piezas pero comparte un
solo esqueleto (`mvr_male.chr`, 30 huesos Bip02) y sus animaciones
genéricas existen (`GenFStand1`, `GenFRunning1`, `GenFAtk1`, variante `-C`
de puños de vagabundo). Toca reutilizar el pipeline para vestirlo.

## What Changes

- `scripts/converters/o3d_to_skinglb.py`: acepta varios `--o3d` y fusiona
  sus mallas en un solo `.glb` con el mismo esqueleto (piezas del cuerpo).
- `scripts/converters/setup_player_model.py`: combina `mvr_male.chr` +
  piezas `Part_mVag01Upper/Hand/Foot` + `Part_maleHead06` +
  `Part_maleHair06` + animaciones `AtkStand-15` (stand), `AtkWalk-15`
  (walk) y `GenFAtk1-C` (atk1) en `PlayerMvr.glb` (no versionado).
- `godot_project/scripts/player.gd`: monta `PlayerMvr.glb` si existe
  (stand en loop, walk al moverse, atk1 al golpear con vuelta a
  locomoción, encarando a la víctima); sin modelo mantiene la cápsula
  azul + punch de escala.
- `main.gd` (sim): comprueba avatar montado y locomoción activa.

## Capabilities

### New Capabilities

- `player-avatar`: avatar del jugador con modelo FlyFF animado.

### Modified Capabilities

(none)

## Impact

- Solo `scripts/converters/` + `player.gd` + sim en `main.gd`. Sin
  cambios en datos ni gameplay salvo la representación visual.
- El `.glb` del jugador no se versiona (derivable por cada dev, como
  monstruos y terreno).
