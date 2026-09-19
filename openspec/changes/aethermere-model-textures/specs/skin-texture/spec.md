## Purpose

Jugador y monstruos muestran sus texturas pintadas del cliente en vez de gris liso.

## ADDED Requirements

### Requirement: Modelos con texturas reales

Los `.glb` de personajes SHALL embeber la textura pintada de cada
pieza (`<nombre de flyff_texture>.png` provisto en `--tex-dir`,
insensible a mayúsculas) como `baseColorTexture` sobre TEXCOORD_0. Sin
PNG para una pieza SHALL mantener el blanco actual para esa pieza.

#### Scenario: Avatar con ropa y cara

- **WHEN** `PlayerMvr.glb` se genera con `--tex-dir` completo y arranca la escena
- **THEN** el modelo visible lleva ropa de vagabundo, cara y pelo en vez de blanco

#### Scenario: Repliegue sin texturas

- **WHEN** el `.glb` se genera sin `--tex-dir` o falta un PNG
- **THEN** el juego arranca igual y esa pieza se ve blanca como hoy

### Requirement: Monstruos con texturas reales

Cada `.glb` de `monsters.json` SHALL embeber su `<modelo>.dds` del
cliente cuando exista en `--tex-dir`; el loro sin clip de ataque SHALL
seguir sin animación pero con textura si la tiene.

#### Scenario: Caza con liebre texturada

- **WHEN** se juega con modelos regenerados con texturas
- **THEN** `Mvr_PetCat1` y el resto muestran su pintura en vez de gris
