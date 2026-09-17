## Context

`aethermere-base` está archivada; `openspec/specs/` tiene `flyff-parsers`,
`game-data` y `godot-base` estables. Los JSON de `data/` están validados
(10 items, 5 monstruos, quest_101 → quest_102, 2 diálogos). La escena
principal arranca en `ironhold` con jugador 3ª persona y HUD HP/MP/EXP.

## Goals / Non-Goals

**Goals:**

- Slice jugable verificable: hablar → aceptar → cazar → completar →
  desbloquear → loot en inventario.
- Lógica de misiones testeable sin input manual (`--sim-quest` headless).
- Todo contenido visible sigue siendo lore nuevo (Aethermere).

**Non-Goals:**

- Modelos/animaciones reales (placeholders cápsula; Fase 5).
- Combate a distancia, habilidades activas, equipo, tiendas, guardado.
- Balance final (números de ejemplo coherentes con `data/`).

## Decisions

- **`quest_manager` como autoload** (igual que `GameData`): estado global
  de misiones accesible desde diálogo, monstruos y HUD. Alternativa:
  nodo en la escena — descartada; el estado debe sobrevivir a cambios
  de escena futuros.
- **Monstruos placeholder instanciados desde `monsters.json`** (1 nodo por
  tipo en zona, con conteo extra de `mon_001` para la misión): la misión
  101 exige 5 muertes y hay un solo tipo de liebre en datos. Se generan
  5 instancias de `mon_001` + 1 de cada otro tipo.
- **Combate melee simple** (clic, alcance 2.5 m, daño = poder de
  `Ember Slash` + 2 base): sin cooldowns ni animaciones; suficiente para
  el slice. Habilidades activas en propuesta posterior.
- **Simulación headless en `main.gd`** (`--sim-quest`): acepta la 101,
  reporta 5 muertes, verifica recompensas y desbloqueo de la 102,
  imprime `SIM-QUEST PASS/FAIL` y sale. Alternativa: test manual en
  editor — descartada como única verificación; no es repetible.

## Risks / Trade-offs

- [Riesgo] IA errante placeholder parece muerta → Mitigación: deambulan y
  dañan por contacto; suficiente para el slice.
- [Riesgo] Diálogo y misión se desincronizan (aceptar dos veces) →
  Mitigación: `quest_manager` ignora aceptados/completados repetidos.
- [Riesgo] Controles solo teclado+ratón → Mitigación: documentado; mando
  en propuesta posterior.

## Migration Plan

No aplica (sin despliegue). Rollback = revert del commit.

## Open Questions

- ¿Daño de habilidades con fórmula completa (ataque - defensa)? Se decide
  en la propuesta de combate; aquí daño fijo documentado.
