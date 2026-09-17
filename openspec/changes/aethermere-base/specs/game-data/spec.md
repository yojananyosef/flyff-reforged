## Purpose

Esta capacidad define los esquemas y archivos JSON con el contenido nuevo del juego (mundo Aethermere): items, monstruos, NPCs, misiones, diálogos, habilidades y zonas, independientes de los datos originales FlyFF.

## ADDED Requirements

### Requirement: Esquemas JSON de datos

El proyecto SHALL proveer un archivo JSON por dominio en `data/`: `items.json`, `monsters.json`, `npcs.json`, `quests.json`, `dialogues.json`, `skills.json` y `zones.json`, cada uno con IDs únicos y referencias cruzadas válidas.

#### Scenario: Validación de datos

- **WHEN** se ejecuta el validador de datos sobre `data/`
- **THEN** todos los archivos parsean como JSON válido, no hay IDs duplicados y toda referencia (`quest.target`, `dialogue.next`, `npc.quests_available`) apunta a un ID existente

### Requirement: Contenido inicial de Aethermere

Los datos SHALL incluir al menos 1 zona (`ironhold`), 1 NPC con diálogo ramificado, 2 misiones encadenadas, 5 monstruos, 10 items y 3 habilidades, con nombres y textos originales (sin copiar textos de FlyFF).

#### Scenario: Contenido mínimo cargable

- **WHEN** se cargan los JSON en el validador o en Godot
- **THEN** la zona `ironhold` referencia NPCs y monstruos existentes, la misión 101 desbloquea la 102, y el diálogo del NPC inicial tiene al menos 2 nodos con opciones

### Requirement: Mapeo FlyFF → Aethermere

El proyecto SHALL mantener en `data/zones.json` el campo `original_asset_dir` que mapea cada zona nueva a su directorio de assets FlyFF de origen (ej. `ironhold` → `WdMadrigal`).

#### Scenario: Trazabilidad de assets

- **WHEN** se lee `data/zones.json`
- **THEN** cada zona incluye `original_asset_dir` y `display_name` nuevo, sin reutilizar nombres originales como nombre visible
