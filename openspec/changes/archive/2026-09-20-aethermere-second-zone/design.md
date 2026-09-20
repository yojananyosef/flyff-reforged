## Context

Specs estables: `terrain` (HeightMap + snap), `game-data` (JSONs por
`id`), `gameplay` (cadena por `requires`), `props` (colocación por
zona), `npc-models` (slots con `model`), `save` (zona + pos
persistidas). Evidencia: tiles 15–16/05–06 con void 0.00 y cotas
0–1200 m; texturas en `WdMadrigal_15-05.res`; `Mvr_NpcRaundas` con
`.o3d`+`.chr`+`stand/idle1/walk`+2 `.dds`; `setup_npcs.py` lee
`npcs.json` (nuevo modelo sale gratis).

## Goals / Non-Goals

**Goals:**

- Fenmarch jugable de punta a punta (llegar, 5 misiones, volver),
  SIM-QUEST PASS 160 + nuevos, captura en navegador.
- `setup_terrain.py` parametrizado sin romper Ironhold (defectos
  intactos).

**Non-Goals:**

- Tercera zona, minimapa, costo de viaje.

## Decisions

- **Bloque 15–16/05–06, centro (15,06)**: void 0 en los 4 tiles,
  relieve de altiplano (contrasta con la costa), texturas en un solo
  `.res`.
- **Slots NPC desde datos**: `npcs.json` gana `x,z`; `npc_setup()`
  posiciona `$NPC`/`$NPC2` según la zona (máx. 2 por zona; el resto se
  avisa y se omite). Ironhold conserva (3,0) y (-4,2).
- **Portal como anillo + `E`**: toro dorado (reutiliza `MoveMarker`)
  en `zones.json travel {to, x, z}` por zona (lejos de los NPC para
  no solaparse); prioridad de `E`: anillo (< 1.5 m) > NPC cercano >
  anillo (< 3 m).
- **Viaje = set zona + save + reload**: `SaveManager` ya persiste
  zona+pos; al recargar, `load_game` deja al jugador en el spawn
  guardado. Se guarda ANTES con la pos del spawn destino para
  aterrizar limpio.
- **Reutilizar modelos de monstruos**: 4 fichas nuevas con stats
  4–7 sobre `Mvr_PetDog1/Mvr_Buur/Mvr_Dreamflame01/Mvr_PetParrot`
  (sin conversiones nuevas).
- **Cadena 201–205**: espejo de la 101–110 en pequeño (5 misiones,
  `requires quest_110` la primera, giver `npc_003`).

## Risks / Trade-offs

- [Riesgo] Spawn en pendiente fuerte → Mitigación: búsqueda de llano
  con el script y `spawn_point` ajustado; el sim lo verifica.
- [Riesgo] Terreno de 1200 m rompe la cámara/niebla → Mitigación:
  captura; el rebase −100 y `WATER_Y` se parametrizan por zona si
  hace falta.
- [Riesgo] Recarga pierde buffs/estado transitorio → Mitigación:
  aceptado (como morir); el save cubre oro/inventario/misiones/nivel.

## Migration Plan

No aplica (zona nueva; Ironhold intacto).

## Open Questions

- Ninguna bloqueante.
