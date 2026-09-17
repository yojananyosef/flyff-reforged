## Context

Proyecto verde: repo vacío con `openspec/` y carpetas base. Ver `proposal.md`
para la motivación. Restricciones: assets FlyFF originales no se versionan;
`.res` no se descifra en esta fase; `.o3d` solo se investiga; todo el contenido
visible (nombres, textos) es nuevo (Aethermere).

## Goals / Non-Goals

**Goals:**

- Pipeline Python → JSON → Godot demostrable de extremo a extremo.
- Datos nuevos validables por script antes de tocar Godot.
- Escena Godot mínima que arranque y muestre la zona inicial.

**Non-Goals:**

- Descifrado completo de `.o3d` / `.res` (solo investigación documentada).
- Red, multijugador, combate completo o inventario (fases posteriores).
- Calidad final de arte o balance (solo datos de ejemplo coherentes).

## Decisions

- **Parsers en Python estándar (`struct`, `json`, `pathlib`) sin dependencias.**
  Alternativa: construct/kaitai — descartadas para no añadir instalación en Fase 0.
- **JSON a mano para datos, con validador propio.**
  Alternativa: SQLite — descartada; JSON es difable, legible y Godot lo carga nativo.
- **Godot 4 con GDScript y autoloads (`game_manager`, `dialogue_manager`, `quest_manager`).**
  Alternativa: C# — descartada; GDScript baja la fricción para iterar el MVP.
- **`.o3d` fuera del camino crítico:** el MVP arranca con primitivas/placeholders
  y los modelos reales se integran en Fase 5. Evita bloquear gameplay por reverse engineering.
- **Texturas UI convertidas a `.png` con Pillow; audio sin conversión.**
  Alternativa: importar `.tga`/`.dds` directo en Godot — se pospone para no
  depender del importador en la base.

## Risks / Trade-offs

- [Riesgo] El cuerpo del `.o3d` no se descifra → Mitigación: MVP con placeholders; investigación aislada en `docs/`.
- [Riesgo] Divergencia entre JSONs (IDs rotos) → Mitigación: validador de referencias cruzadas en CI/manual.
- [Riesgo] Versiones de Godot distintas entre devs → Mitigación: fijar versión 4.x en README y `project.godot`.

## Migration Plan

No aplica (proyecto nuevo, sin despliegue). Rollback = revert del commit.

## Open Questions

- ¿Versión exacta de Godot 4 (4.2 vs 4.3+) a fijar? Se decide al crear `project.godot`.
- ¿Esquema final de keyframes `.ani` (glTF vs JSON propio)? Se decide tras parsear los primeros archivos reales.
