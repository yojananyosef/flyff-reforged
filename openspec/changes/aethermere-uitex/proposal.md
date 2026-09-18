## Why

La UI es 100% controles default de Godot sobre fondo transparente: hay
1033 texturas del cliente sin usar, incluidos skins de ventana con borde
dorado (diálogo, tienda, mensajes) e iconos-orbe para las barras. Esta
propuesta viste los 3 paneles y las barras con assets reales, sin
conversor (Godot importa `.tga` nativo).

## What Changes

- `setup_ui_textures.py`: copia 5 archivos curados a
  `godot_project/textures/ui/` (gitignorado, como el audio).
- Diálogo, tienda e inventario → `WndMessagebox`
  (NinePatchRect con márgenes; carga en runtime con repliegue a
  transparente si faltan). (`WndDialog` se descartó: trae marcos
  horneados que chocan con el contenido.)
- Orbes `BarRed/Green/Sky` como iconos junto a HP/MP/EXP.
- Se descartan botones con texto inglés horneado (`ButOk2` dice "Ok":
  chocaría con las etiquetas en español).

## Capabilities

### New Capabilities

- `uitex`: setup de texturas UI y aplicación en HUD/diálogo/tienda.

### Modified Capabilities

- (ninguna)

## Impact

- Sin setup, el juego se ve como antes (repliegue silencioso + aviso).
- Sin cambios en `data/`, lógica ni layout (mismos rects).
