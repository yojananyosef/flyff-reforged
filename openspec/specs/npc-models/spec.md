## Purpose

Maren y Pell muestran cuerpo FlyFF con idle en vez de cápsulas lisas.

## Requirements

### Requirement: NPC con modelo y repliegue

Cada NPC con `model` en `npcs.json` SHALL instanciar su `.glb`
texturado cuando exista (ocultando la cápsula), con clip `stand`/`idle`
en bucle y encarado al centro del campamento; sin `.glb` SHALL mostrar
la cápsula actual.

#### Scenario: Anciano con cuerpo

- **WHEN** arranca la escena con modelos generados
- **THEN** Maren y Pell visibles con ropa y cara, en idle, mirando al campamento

#### Scenario: Repliegue sin modelos

- **WHEN** no hay `.glb` de NPC
- **THEN** el juego arranca con las cápsulas verde/naranja como hoy
