## Context

Specs estables: `gameplay` (paneles), `audio` (precedente de setup por
dev + repliegue). Fondos actuales: `ColorRect` (diálogo, tienda) o nada
(inventario). Barras `ProgressBar` default.

## Goals / Non-Goals

**Goals:**

- Los 3 paneles y las 3 barras con piel FlyFF, verificable en captura.
- Cero rotura sin setup: todo carga en runtime con fallback.

**Non-Goals:**

- Botones con textura (texto horneado en inglés; se queda el tema default).
- Iconos de items (vienen en `.res` empaquetados; fuera de alcance).
- Tema global `.tres` (overrides puntuales bastan en el MVP).

## Decisions

- **NinePatchRect + carga en runtime**, no referencias en `.tscn`: un
  `ext_resource` a un archivo ausente rompe la escena; `load()` con
  nulo es degradación elegante. Alternativa: versionar las texturas —
  descartada; misma política que audio (binarios del cliente fuera).
- **Márgenes de parche 16 px** sobre borde dorado (~6 px): preserva
  esquinas estirando el centro plano.
- **Orbes 12×14 junto a barras** (no como fill): son iconos, no
  texturas estirables; el fill plano actual sigue.
- **`WndMessagebox` en los 3 paneles**: sin widgets horneados, estira
  limpio (`WndDialog` se descartó por marcos horneados que chocaban).

## Risks / Trade-offs

- [Riesgo] Estirado 2× del messagebox se ve blando → Mitigación: centro
  plano + verificación en captura; aceptable para MVP.
- [Riesgo] TGA con alfa raro en Godot → Mitigación: captura lo confirma;
  orbes con halo se descartan si salen mal.

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna.
