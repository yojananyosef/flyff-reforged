## Purpose

El cuerpo a cuerpo se ve y se siente: el monstruo mantiene distancia y mira
al pegar, y el jugador ataca solo con doble clic.

## Requirements

### Requirement: Distancia y encarado del monstruo

Con agro, el monstruo SHALL frenar a 1.1 m del jugador (no avanzar más) y
SHALL encararlo de forma instantánea al aplicar el golpe por contacto. La
distancia en contacto SHALL mantenerse ≥ 0.8 m.

#### Scenario: Frenada

- **WHEN** un lobo con agro alcanza al jugador quieto
- **THEN** tras 1 s sigue a ≥ 0.8 m (no debajo de él)

#### Scenario: Encarado

- **WHEN** un monstruo aplica daño por contacto
- **THEN** su yaw difiere del rumbo al jugador en < 0.5 rad

### Requirement: Básicos automáticos con doble clic

El doble clic a un monstruo SHALL fijarlo y activar auto-ataque: el jugador
camina hasta el rango y repite básicos con cooldown de 0.9 s hasta que el
objetivo muere o se fija otro destino/monstruo. Un clic simple al suelo
SHALL desactivarlo.

#### Scenario: Caza automática

- **WHEN** se activa auto-ataque a una liebre a 6 m
- **THEN** el jugador se acerca y el HP de la liebre baja sin más clics

### Requirement: Básicos con ritmo y gesto

Cada básico manual o automático SHALL respetar 0.9 s de cooldown (el segundo
inmediato se rechaza) y SHALL mostrar un gesto visible (punch de escala en
la malla del jugador) además del sonido ya existente.

#### Scenario: Cooldown

- **WHEN** se lanzan dos básicos en el mismo frame
- **THEN** el primero impacta y el segundo se rechaza
