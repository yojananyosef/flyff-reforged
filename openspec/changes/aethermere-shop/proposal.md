## Why

Pell Bryn existe en datos como mercader pero es decorado: no se puede
comerciar ni equipar nada, y el oro no existe. El Recruit Blade y la
túnica del inventario son texto. Esta propuesta activa la economía
mínima: oro, tienda de Pell, compra/venta y equipo que sí cambia
ataque y defensa.

## What Changes

- `items.json`: bonus en equipo (`attack_bonus`/`defense_bonus` en
  `item_001`/`item_002`; compatible, el validador sigue pasando).
- Jugador: `gold` (30 inicial), `buy`/`sell`/`equip`/`unequip`,
  `attack_stat()`/`defense_stat()` usados por las fórmulas; oro por
  muerte (`nivel × 2`).
- Pell en escena (grupo `npcs`, E abre al más cercano); botón Comerciar
  en diálogo si el NPC es mercader; panel de tienda (comprar stock fijo,
  vender no-misión a mitad de precio, sin vender lo equipado).
- Sonidos: comprar/vender reutilizan `reward`/`ui_click`.

## Capabilities

### New Capabilities

- `shop`: oro, tienda de Pell, compra/venta y equipo.

### Modified Capabilities

- `game-data`: `items.json` gana bonus de equipo (compatible).
- `gameplay`: fórmulas usan stats con equipo; la simulación cubre la tienda.

## Impact

- Sin migraciones: partidas no persistidas aún; inventario inicial igual.
- Rebalance leve: espada +3 deja el básico en 8 a liebre (4 golpes).
