## Purpose

Completar el contenido de misiones del MVP.

## MODIFIED Requirements

### Requirement: Contenido inicial de Aethermere

Los datos SHALL incluir al menos 1 zona (`ironhold`), 1 NPC con diálogo
ramificado, 10 misiones encadenadas (101 → ... → 110), 5 monstruos,
10 items y 3 habilidades, con nombres y textos originales.

#### Scenario: Contenido mínimo cargable

- **WHEN** se cargan los JSON en el validador o en Godot
- **THEN** la zona `ironhold` referencia NPCs y monstruos existentes, la
  misión 101 desbloquea la 102 y así hasta la 110, y el diálogo del NPC
  inicial tiene al menos 2 nodos con opciones
