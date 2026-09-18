## Why

Jugando el combate cuerpo a cuerpo se rompe en 4 puntos:

1. Varios atacantes golpean mirando a otro lado, no al jugador.
2. Al acercarse, los monstruos se meten debajo del jugador y lo levantan
   como si saltara (persiguen hasta 0.25 m y empujan la cápsula).
3. El clic no sirve para moverse: solo ataca al más cercano en rango y falla
   en silencio si no hay nada a 2.5 m.
4. Los básicos no se sienten: el jugador es una cápsula sin gesto de golpe
   y hay que clicar cada vez; parece que solo existen las skills.

## What Changes

- `monster.gd`: con agro frena a 1.1 m del jugador (no se mete debajo ni lo
  empuja) y al golpear encara al jugador de golpe (snap, no lerp).
- `player.gd`: clic al suelo (rayo central) = destino de marcha con anillo
  marcador; WASD lo cancela. Doble clic a monstruo = fijar + ir + básicos
  automáticos hasta matarlo. Básicos con cooldown 0.9 s y gesto visible
  (punch de escala en la malla). Clic a monstruo en rango sigue golpeando
  al acto; fuera de rango solo fija.
- `hud.gd`/`main.tscn`: pista actualizada (`Clic ir/fijar · Doble-clic
  auto-atacar`).
- Sim: frenada (distancia ≥ 0.8 en contacto), encarado al golpear (< 0.5 rad),
  click-mover llega, auto-básicos bajan HP, cooldown bloquea el segundo
  básico inmediato.

## Capabilities

### New Capabilities

- `clickmove`: destino de marcha con clic + marcador + cancelación con WASD.
- `melee`: básicos automáticos con doble clic, cooldown y gesto visible;
  monstruo frena a 1.1 m y encara al golpear.

### Modified Capabilities

(none)

## Impact

- `monster.gd`, `player.gd`, `hud.gd` (nada), sim en `main.gd`, pista en
  `main.tscn`. Sin cambios en datos, daño o animaciones.
- El ataque clásico (clic al más cercano) se conserva cuando el rayo no da
  ni a bicho ni a suelo.
