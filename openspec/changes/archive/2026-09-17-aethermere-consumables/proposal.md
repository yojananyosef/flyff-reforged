## Why

El pan y los tónicos ocupan inventario y tienda pero no hacen nada: la
única cura es Bandage (nivel 3) y el MP solo se gasta. El jugador recibe
recompensas inútiles durante 2 niveles y la tienda vende objetos muertos.
Hacerlos usables cierra el loop cazar → gastar → recuperar.

## What Changes

- `items.json`: `use_effect` en consumibles (pan +25 HP, tónico +20 MP).
- `player.use_item(id)`: exige tipo consumible, unidad disponible, efecto
  aplicable (no curar a tope) y cooldown compartido de 3 s; consume,
  aplica y suena `heal`.
- Botón Usar en el panel de inventario sobre la selección.
- Validador exige `use_effect` en todo consumible; sim cubre los casos.

## Capabilities

### New Capabilities

- `consumables`: efectos usables de objetos.

### Modified Capabilities

- `game-data`: consumibles con `use_effect` (compatible).
- `gameplay`: la simulación cubre usar objetos.

## Impact

- Sin cambios en economía (precios iguales) ni en combate.
- Bandage sigue siendo la cura fuerte; el pan es sostén barato.
