## MODIFIED Requirements

### Requirement: Oro y comercio

El jugador SHALL empezar con 30 de oro, ganar `nivel × 2` por muerte,
comprar del stock (pan, tónico, espada, túnica y tier Fenmarch con
requisito de nivel) si le alcanza y vender objetos no-misión
no-equipados a mitad de precio.

#### Scenario: Compra y venta

- **WHEN** compra 1 pan (4) y vende 1 pelaje (3 → 1)
- **THEN** el oro pasa de 30 a 27 y el inventario refleja ambos
  movimientos

### Requirement: Tienda de Pell

Pell SHALL estar en escena; E SHALL abrir el diálogo del NPC más
cercano; el diálogo SHALL mostrar Comerciar solo si es mercader; la
tienda SHALL listar stock con precios (8 artículos con el tier
Fenmarch), vender lo vendible y cerrar con E/ratón.

#### Scenario: Comercio con Pell

- **WHEN** E junto a Pell y clic en Comerciar
- **THEN** se abre la tienda con 8 artículos y el oro visible
