## Purpose

Vestir la interfaz con texturas reales del cliente: skins de ventana en
los 3 paneles e iconos-orbe en las barras, con degradación elegante.

## ADDED Requirements

### Requirement: Setup de texturas UI

El script SHALL copiar los 5 archivos curados a
`godot_project/textures/ui/`; la carpeta SHALL estar gitignorada.

#### Scenario: Setup local

- **WHEN** se ejecuta `setup_ui_textures.py --client <app> --out godot_project/textures/ui`
- **THEN** existen 5 archivos y el resumen dice `5/5`

### Requirement: Paneles con skin

Los 3 paneles (diálogo, tienda, inventario) SHALL usar `WndMessagebox`
como fondo NinePatch; sin archivos SHALL verse como antes sin errores.

#### Scenario: Capturas con piel

- **WHEN** se capturan diálogo, tienda e inventario con setup hecho
- **THEN** los 3 muestran borde dorado del cliente
