## Purpose

Convertir los modelos 3D del cliente FlyFF v21 a formatos estándar:
parser `.o3d` → JSON intermedio y conversor → `.glb` importable por Godot.

## ADDED Requirements

### Requirement: Parser .o3d completo

El parser SHALL leer header (XOR `0xCD`), colisión, huesos base,
objetos SKIN/NORMAL (±bump), índices u16, physique, materiales
(+ nombre de textura), bloques de material y animaciones embebidas,
cuadrando la longitud total del archivo.

#### Scenario: Batch del cliente

- **WHEN** se ejecuta sobre los 6202 `.o3d` del cliente
- **THEN** ≥98% cuadran al byte exacto con índices en rango de sus
  vértices, y los fallos quedan listados con motivo

### Requirement: Conversor a .glb

El conversor SHALL producir `.glb` con posiciones, normales, UV,
índices, joints/weights y un material por objeto (nombre de textura en
extras), sin dependencias externas.

#### Scenario: Importación en Godot

- **WHEN** se importan 3 `.glb` convertidos en un proyecto Godot limpio
- **THEN** la importación termina sin errores y una escena con los 3
  instanciados muestra geometría coherente
