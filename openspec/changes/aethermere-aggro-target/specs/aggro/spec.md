## Purpose

Los monstruos reaccionan al jugador: dejan de deambular al entrar en
combate, persiguen y vuelven a su rutina al perder el interés.

## ADDED Requirements

### Requirement: Agro por proximidad y por daño

El monstruo SHALL fijar agro al jugador si entra en su `aggro_range`
(liebre/cuervo 0 = mansos, solo contacto/daño; jabalí 5, wisp 6, lobo 8),
si le golpea por contacto o si recibe daño suyo. Con agro, el deambular
aleatorio queda suspendido.

#### Scenario: Proximidad

- **WHEN** el jugador se acerca a 5 m de un lobo vivo (rango 8)
- **THEN** en ≤ 1 s el lobo tiene agro fijado en el jugador

#### Scenario: Manso

- **WHEN** el jugador se queda a 4 m de una liebre viva 1 s
- **THEN** la liebre no fija agro (solo contacto o daño la provoca)

#### Scenario: Daño

- **WHEN** un monstruo fuera de rango de proximidad recibe daño del jugador
- **THEN** fija agro en el jugador

### Requirement: Persecución e interrupción del paseo

Con agro, el monstruo SHALL moverse hacia el jugador a 2.8 m/s mirándolo,
en vez de seguir su rumbo aleatorio. La distancia al jugador SHALL
reducirse mientras persigue.

#### Scenario: Caza

- **WHEN** un monstruo con agro está a 6 m del jugador quieto
- **THEN** tras 1 s la distancia es claramente menor que la inicial

### Requirement: Leash y retorno

Si el jugador se aleja a más de 14 m o deja de ser válido, el monstruo
SHALL soltar el agro y retomar el deambular.

#### Scenario: Huida

- **WHEN** el jugador teletransporta lejos (> 14 m) de un monstruo con agro
- **THEN** el monstruo suelta el agro y vuelve a rumbo aleatorio
