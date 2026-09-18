## Purpose

Los monstruos con modelo se desplazan con animación de marcha y telegrafían
sus golpes con animación de ataque, en vez de deslizar quietos.

## Requirements

### Requirement: Marcha animada al vagar

El monstruo con modelo SHALL reproducir en bucle su clip de marcha
(`walk`/`Walk`) mientras deambula, y orientar su cuerpo hacia la dirección
de marcha. Si el modelo no trae clip de marcha, SHALL mantener `stand`.

#### Scenario: Vagar con walk

- **WHEN** un Cinder Hare con modelo deambula con clip `walk` disponible
- **THEN** su `AnimationPlayer` reproduce `walk` en bucle y su yaw mira
  hacia su vector de movimiento

#### Scenario: Repliegue sin walk

- **WHEN** el modelo no trae clip de marcha
- **THEN** el monstruo mantiene `stand` en bucle y se mueve igual

### Requirement: Ataque telegrafiado por contacto

Al aplicar daño por contacto, el monstruo con clip de ataque SHALL
reproducir `atk1`/`atk2` (o variantes `att1`/`att2`) una vez sin bucle y
luego volver a `walk`/`stand`. El daño y el cooldown de 1 s no cambian. Sin
clip de ataque, el daño se aplica sin animación.

#### Scenario: Golpe con animación

- **WHEN** un Mossback Boar a < 1.4 m aplica daño con cooldown libre
- **THEN** reproduce un clip `atk*` completo una vez y el jugador recibe el
  daño de la fórmula vigente

#### Scenario: Loro sin ataque

- **WHEN** un Hollow Crow (sin clips `atk`/`die`) aplica daño o muere
- **THEN** el daño y la muerte ocurren igual, sin animación, y el sim lo
  acepta como repliegue documentado

### Requirement: Muerte sin cambios

La muerte SHALL mantener el comportamiento vigente: clip `die*` una vez si
existe y liberación al terminar; si no existe, liberación inmediata.

#### Scenario: Muerte con die

- **WHEN** un monstruo con `die1` llega a 0 HP
- **THEN** reproduce `die1` una vez y se libera al terminar la animación
