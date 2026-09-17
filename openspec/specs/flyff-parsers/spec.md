# flyff-parsers Specification

## Purpose
Esta capacidad cubre los parsers Python que leen los formatos del cliente FlyFF v21 y los convierten a JSON intermedio, más el extractor de archivos sueltos y la investigación documentada del formato `.o3d`.

## Requirements

### Requirement: Parser de esqueletos .chr

El parser SHALL leer archivos `.chr` del cliente y producir un JSON con la jerarquía de huesos y matrices de bind pose.

#### Scenario: Conversión exitosa de .chr

- **WHEN** se ejecuta el parser sobre un archivo `.chr` válido del cliente
- **THEN** se genera un JSON con nombre raíz, lista de huesos hijos y matrices 4x4, y el proceso termina con código 0

#### Scenario: Archivo .chr inexistente

- **WHEN** se ejecuta el parser sobre una ruta que no existe
- **THEN** el parser termina con código distinto de 0 y un mensaje de error que incluye la ruta

### Requirement: Parser de animaciones .ani

El parser SHALL leer archivos `.ani` del cliente y producir un JSON con velocidad, huesos y keyframes (matrices 4x4).

#### Scenario: Conversión exitosa de .ani

- **WHEN** se ejecuta el parser sobre un archivo `.ani` válido del cliente
- **THEN** se genera un JSON con `speed`, `bone_count` y keyframes por hueso, y el proceso termina con código 0

### Requirement: Extractor de archivos sueltos

El extractor SHALL copiar audio (`.ogg`/`.wav`), texturas UI (`.tga`/`.bmp`/`.dds`) y modelos (`.chr`/`.ani`) desde un directorio del cliente a `assets/` preservando la organización por tipo, sin intentar descifrar `.res`.

#### Scenario: Extracción de cliente local

- **WHEN** se ejecuta el extractor apuntando al directorio del cliente FlyFF extraído
- **THEN** los archivos `.ogg`, `.wav`, `.tga`, `.dds`, `.chr` y `.ani` aparecen en sus carpetas destino bajo `assets/` y se imprime un resumen de conteos

### Requirement: Investigación .o3d documentada

El proyecto SHALL documentar en `docs/` el estado del reverse engineering del formato `.o3d` (header XOR `0xCD`, versión, hash y preguntas abiertas del cuerpo del modelo).

#### Scenario: Documento de investigación presente

- **WHEN** se revisa la carpeta `docs/`
- **THEN** existe un documento que describe el header `.o3d` conocido y los bytes pendientes de descifrar
