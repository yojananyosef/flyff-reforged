## Purpose

El oro de Fenmarch se gasta en Fenmarch: un mercader propio junto al campamento evita peregrinar a Ironhold por pan y tónicos.

## Requirements

### Requirement: Mercader de Fenmarch

El juego SHALL generar en `fenmarch` un segundo NPC mercader con cuerpo, diálogo propio y botón Comerciar; la tienda SHALL abrirse con él igual que con Pell.

#### Scenario: Comercio en el ridge

- **WHEN** se pulsa E junto al mercader de Fenmarch y se clickea Comerciar
- **THEN** la tienda se abre con los 8 artículos y el oro visible
