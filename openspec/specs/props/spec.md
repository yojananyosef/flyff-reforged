## Purpose

El campamento de Ironhold muestra tiendas y muros con colisión en vez de un descampado.

## Requirements

### Requirement: Estructuras del campamento

El juego SHALL instanciar los props de `zones.json ironhold.props`
(`model`, `x`, `z`, `yaw`) con su `.glb` texturado, apoyados en el
suelo (`ground_height`) y con colisión estática que bloquee al jugador.
Sin `.glb` generados SHALL arrancar sin props.

#### Scenario: Tiendas junto al spawn

- **WHEN** arranca la escena con props generados
- **THEN** hay tiendas y muros visibles alrededor del spawn con su pintura

#### Scenario: Muros que bloquean

- **WHEN** el jugador camina contra un prop
- **THEN** no lo atraviesa (colisión estática)

#### Scenario: Repliegue sin props

- **WHEN** no hay `.glb` de props
- **THEN** el juego arranca igual, sin estructuras
