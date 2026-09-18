## Purpose

Ironhold muestra el suelo pintado del cliente con agua y vegetación en vez de verde liso.

## ADDED Requirements

### Requirement: Suelo con texturas reales

El terreno SHALL mapear cada tile a su textura pintada
(`WdMadrigal{XX}-{YY}.dds` del `.res` gemelo) mediante un atlas, con
los caminos y la costa continuos entre tiles. Sin archivos generados
SHALL mantener el verde plano actual.

#### Scenario: Arranque con atlas

- **WHEN** existen `terrain_ironhold.glb` y el atlas y arranca la escena
- **THEN** el Ground visible lleva la pintura (caminos, costa, casas
  pintadas) sin cortes en los bordes de tile

#### Scenario: Repliegue sin atlas

- **WHEN** no hay archivos de terreno generados
- **THEN** el juego arranca con el plano verde 40×40 como hoy

### Requirement: Agua al nivel del mar

El juego SHALL mostrar un plano de agua semi-transparente a la cota
del spec bajo el área de juego, visible donde el relieve baja (hoyas y
costa) y oculto por el terreno donde este emerge; el campamento SHALL
quedar seco.

#### Scenario: Costa con agua

- **WHEN** se mira una hoya bajo la cota con archivos generados
- **THEN** hay lámina de agua sobre las zonas bajo la cota del spec

### Requirement: Vegetación donde la pintura es verde

El juego SHALL instanciar hierba (y árboles donde el verde es denso)
en puestos deterministas sobre el nivel del mar y en pendiente suave,
coincidiendo con las zonas verdes de la pintura.

#### Scenario: Hierba en el verde

- **WHEN** se juega con archivos generados
- **THEN** hay matas y árboles instanciados sobre verde pintado y
  ninguno bajo el agua
