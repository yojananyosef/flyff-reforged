## Purpose

El jugador se ve como un vagabundo FlyFF animado en vez de una cápsula azul lisa.

## Requirements

### Requirement: Avatar con modelo y repliegue

El jugador SHALL instanciar `models/PlayerMvr.glb` cuando exista,
ocultando la cápsula azul; cuando no exista SHALL mostrar la cápsula
azul actual con el punch de escala. La colisión y la lógica SHALL quedar
intactas en ambos casos.

#### Scenario: Arranque con modelo

- **WHEN** existe `PlayerMvr.glb` y arranca la escena
- **THEN** el cuerpo visible es el modelo y la cápsula queda oculta

#### Scenario: Repliegue sin modelo

- **WHEN** no hay `PlayerMvr.glb`
- **THEN** el jugador es la cápsula azul con punch de escala como hoy

### Requirement: Locomoción y ataque animados

Con modelo, el jugador SHALL reproducir `stand` en reposo, `walk` en
bucle mientras se desplaza, y un clip `atk1` por golpe que vuelve a la
locomoción al terminar. Al golpear SHALL encarar a la víctima (el
modelo no es simétrico como la cápsula).

#### Scenario: Caminar con walk

- **WHEN** el jugador con modelo se desplaza (WASD o click-mover)
- **THEN** su AnimationPlayer reproduce `walk` en bucle

#### Scenario: Golpe con atk1

- **WHEN** el jugador con modelo aplica un básico
- **THEN** reproduce `atk1` una vez y vuelve a `stand`/`walk`

#### Scenario: Encarado al golpear

- **WHEN** el jugador con modelo golpea quieto a una víctima
- **THEN** lo visible queda orientado hacia ella (< 0.5 rad)
