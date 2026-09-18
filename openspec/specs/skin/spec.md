## Purpose

Vestir a los monstruos con modelos reales animados del cliente:
exportador skinned+animado, curaduría e integración mínima en el juego.

## ADDED Requirements

### Requirement: Exportador skinned y animado

El exportador SHALL producir por modelo un `.glb` con nodos del
`.chr`, skin (IBMS de `m1`, joints `usebones[matIdx//3]`) y una
animación por `.ani` (canales de rotación/traslación por hueso).

#### Scenario: Rangda ataca

- **WHEN** se convierte Rangda + `atk1` y se reproduce en visor
- **THEN** la bind pose es sana y 3 frames muestran flexión sin explosión

### Requirement: Monstruos con modelo en el juego

Cada monstruo SHALL declarar `model` en `monsters.json`; con setup
hecho SHALL instanciar su `.glb` (stand en loop, die al morir)
manteniendo colisión y lógica; sin modelo SHALL usar cápsula.

#### Scenario: Caza con modelo

- **WHEN** se juega con modelos generados y muere un monstruo
- **THEN** se ve el modelo real, suena la muerte y el progreso cuenta
  igual (sim PASS)
