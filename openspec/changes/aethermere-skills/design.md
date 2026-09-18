## Context

Specs estables: `game-data` (skills con coste/poder), `gameplay`
(combate placeholder), `audio`. El ataque básico hace 14 fijos y el
daño por contacto usa `attack` plano; el MP solo baja con habilidades
que no existen.

## Goals / Non-Goals

**Goals:**

- Cada skill de `skills.json` usable con efecto distinto y verificable.
- Fórmula única documentada para todo el daño físico.
- Feedback mínimo: barra con cooldowns + tinte en Bulwark.

**Non-Goals:**

- Skill trees, puntos de skill o respec (solo auto-aprendizaje por nivel).
- Daño mágico/elemental separado (todo físico por ahora).
- Animaciones de casteo (placeholder: mismo gesto + sonidos).

## Decisions

- **Fórmula `max(1, atk + power − def)`**: usa los campos que ya hay en
  datos (`attack`, `power`, `defense`). Alternativa: porcentajes —
  descartada; resta plana es legible y testeable.
- **Cooldowns fijos en código** (Ember 4 s, Bulwark 20 s, Bandage 15 s;
  Bulwark dura 5 s): `skills.json` no tiene campos de tiempo y no se
  quiere migrar datos en esta propuesta. Se documentan aquí.
- **Ember solo consume cooldown si golpea**: evita castigar el whiff en
  un combate sin animación de ayuda. Bandage/Bulwark consumen siempre.
- **Auto-aprendizaje por nivel** con aviso: sin entrenadores en el MVP.
- **MP regen 3/s, sin regen de HP**: la cura viene de Bandage/Hearthbread
  futuro; mantiene tensión en la caza.

## Risks / Trade-offs

- [Riesgo] Básico flojo (6 a liebre = 5 golpes) frustra → Mitigación:
  Ember (17) lo deja a 2 golpes; es la fantasía del warden.
- [Riesgo] Bulwark + Bandage hacen inmortal al jugador → Mitigación:
  cooldowns largos; números a revisar con testers.

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- Ninguna.
