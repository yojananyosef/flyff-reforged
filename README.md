# FlyFF Reforged — MMORPG desde cero con assets FlyFF v21

Nuevo MMORPG construido desde cero con **Godot 4**, reutilizando los assets
extraídos del cliente FlyFF v21 (audio, texturas UI, esqueletos, animaciones)
con **lore, nombres, diálogos y balance completamente nuevos** (mundo *Aethermere*).

> El código del servidor privado FlyFF
> ([NukeZero/Flyff-v21](https://github.com/NukeZero/Flyff-v21)) se usa **solo
> como referencia** para entender estructuras de datos y mecánicas.
> Nada de ese código se copia a este proyecto.

## Estado

Proyecto en fase de arranque, gestionado paso a paso con
[OpenSpec](https://github.com/Fission-AI/OpenSpec).

- Ver propuestas activas: `openspec/changes/`
- Ver especificaciones estables: `openspec/specs/`
- Flujo: `/opsx-explore` → `/opsx-propose` → `/opsx-apply` → `/opsx-archive`

## Estructura

```text
flyff-reforged/
├── openspec/              # Especificaciones y propuestas (fuente de verdad)
├── scripts/
│   ├── parsers/           # Parsers Python de formatos FlyFF (.chr, .ani, .o3d, .lnd)
│   ├── converters/        # Conversores .o3d/.dds → .glb/.png
│   └── generators/        # Generadores de contenido
├── data/                  # Datos nuevos del juego (items, npcs, quests, dialogues…)
├── assets/                # Assets convertidos desde el cliente FlyFF
├── godot_project/         # Proyecto Godot 4
└── docs/                  # Documentación adicional
```

## Realidad técnica (resumen)

| Formato | Estado |
|---|---|
| `.ogg` / `.wav` | Uso directo, sin conversión |
| `.tga` / `.bmp` / `.dds` (UI) | Conversión simple a `.png` |
| `.chr` (esqueletos) | Parser fácil, formato conocido |
| `.ani` (animaciones) | Parser fácil, formato conocido |
| `.o3d` (modelos 3D) | Reverse engineering (XOR `0xCD` resuelto en header) |
| `.lnd` (terreno) | Parser medio, heightmap exportable |
| `.res` (empaquetados) | Se evita: se usan archivos sueltos + JSONs nuevos |

- ~60% de assets reutilizables directamente
- ~30% necesitan reverse engineering
- ~10% se reconstruyen desde cero (config, servidores, lore)

## Plan por fases (resumen)

1. **Fase 0** — Entorno y estructura (este commit)
2. **Fase 1** — Parsers `.chr`, `.ani`, `.o3d`, `.lnd`
3. **Fase 2** — Conversores → `.glb` / `.png`
4. **Fase 3** — Lore nuevo + JSONs (`items`, `monsters`, `npcs`, `quests`, `dialogues`, `skills`, `zones`)
5. **Fase 4** — Gameplay en Godot (movimiento, diálogos, misiones, combate, inventario)
6. **Fase 5** — Integración de assets convertidos
7. **Fase 6** — Testing y pulido

MVP recortado: 1 zona (Ironhold), 1 clase, 10 misiones, 5 monstruos,
combate básico, UI funcional.

## Jugar en web (GitHub Pages)

Juega sin instalar Godot: **https://yojananyosef.github.io/flyff-reforged/**

> Si ves un 404, activa Pages una vez: repo → Settings → Pages →
> Deploy from a branch → rama `gh-pages` → `/ (root)` → Save.

Controles: **WASD** moverse, **Espacio** saltar, **E** hablar/comerciar,
**clic** atacar, **1/2/3** consumibles, **F3** overlay diagnóstico,
**F5** guardar, **F8** nueva partida. En web el guardado usa IndexedDB
y la música empieza tras el primer clic (política del navegador).

Regenerar el build:

```bash
python3 scripts/build_web.py --out web-dist
```

Requiere Godot 4.7 + templates (incl. `web_nothreads_release`).
El script genera el preset Web con `thread_support=false` (Pages no
envía COOP/COEP), exporta a `web-dist/` y limpia el staging
(`godot_project/data/` y `export_presets.cfg` no se versionan).

## Requisitos

- Python 3.10+
- Godot 4.x
- OpenSpec CLI (`npm install -g @fission-ai/openspec@latest`)
- Blender, GIMP (plugin DDS), Audacity (opcionales, para assets)

## Licencia

MIT — ver `LICENSE`. Los assets originales del cliente FlyFF pertenecen a sus
respectivos dueños y no se redistribuyen aquí; cada uno debe extraerlos de su
propia copia del cliente.
