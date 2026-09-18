## Purpose

Economía mínima de Aethermere: oro, tienda del mercader Pell, compra y
venta, y equipo (arma/armadura) que modifica ataque y defensa.

## Requirements

### Requirement: Oro y comercio

El jugador SHALL empezar con 30 de oro, ganar `nivel × 2` por muerte,
comprar del stock (pan, tónico, espada, túnica) si le alcanza y vender
objetos no-misión no-equipados a mitad de precio.

#### Scenario: Compra y venta

- **WHEN** compra 1 pan (4) y vende 1 pelaje (3 → 1)
- **THEN** el oro pasa de 30 a 27 y el inventario refleja ambos
  movimientos

### Requirement: Equipo

El jugador SHALL equipar 1 arma y 1 armadura desde el inventario;
`attack_stat()` SHALL ser base + bonus del arma y `defense_stat()`
base + bonus de la armadura; desequipar SHALL devolver al inventario.

#### Scenario: Espada puesta

- **WHEN** equipa `item_001` (+3)
- **THEN** `attack_stat()` es 8 y el básico a `mon_001` hace 8 de daño

### Requirement: Tienda de Pell

Pell SHALL estar en escena; E SHALL abrir el diálogo del NPC más
cercano; el diálogo SHALL mostrar Comerciar solo si es mercader; la
tienda SHALL listar stock con precios, vender lo vendible y cerrar con
E/ratón.

#### Scenario: Comercio con Pell

- **WHEN** E junto a Pell y clic en Comerciar
- **THEN** se abre la tienda con 4 artículos y el oro visible
