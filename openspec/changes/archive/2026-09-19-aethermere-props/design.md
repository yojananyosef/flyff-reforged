## Context

Specs estables: `terrain` (HeightMap + `ground_height`), `skin-texture`
(patrón `--tex-dir` e imágenes embebidas), `gameplay` (spawn en
`zones.json`). Evidencia: `o3d_to_glb.py` vuelca geometría + UVs +
`extras.flyff_texture`; texturas de tiendas/muros sueltas en
`Model/Texture/`; cola del `.lnd` sin parsear (se evita por diseño).

## Goals / Non-Goals

**Goals:**

- 3 piezas (2 tiendas + 1 muro reutilizado en 3 tramos) con pintura,
  snap al suelo y colisión; SIM-QUEST PASS + captura en navegador.
- `setup_props.py` deriva todo desde el cliente con PIL.

**Non-Goals:**

- Cola del `.lnd`, puertas/teleports, interiores.

## Decisions

- **`--tex-dir` espejo de `o3d_to_skinglb.py`**: mismo lookup y
  embebido; pieza sin PNG queda blanca (p. ej. material `''` de la
  tienda).
- **Colocación en `zones.json`**: `props: [{model, x, z, yaw}]` junto
  al spawn; la `y` se calcula con `ground_height` (el relieve manda).
- **Colisión con `create_trimesh_collision()`**: exacta y sin datos
  extra; 5 instancias son baratas. Tramo de muro reutilizado 3 veces
  con distinto yaw.
- **Orden de carga tras el terreno**: `_load_props()` después de
  `_load_terrain()` para tener `ground_height` disponible.

## Risks / Trade-offs

- [Riesgo] Pieza flotando/hundida (origen del .o3d no al nivel del
  suelo) → Mitigación: captura + ajuste de `y_offset` por pieza en
  `zones.json` si hace falta.
- [Riesgo] Trimesh pesado en web → Mitigación: 5 instancias pequeñas;
  si el export se resiente se pasa a cajas.
- [Riesgo] V invertida → Mitigación: misma convención que personajes
  (DDS arriba-izquierda); captura de verificación.

## Migration Plan

No aplica. Rollback = borrar `.glb` de props (repliegue).

## Open Questions

- Ninguna bloqueante.
