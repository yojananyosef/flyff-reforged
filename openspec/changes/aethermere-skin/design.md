## Context

Specs estables: `o3dflyff` (geometría), `game-data` (5 monstruos sin
modelo), `gameplay` (monstruos cápsula con estados vivo/muerto).
Evidencia previa en `docs/o3d-proof/`.

## Goals / Non-Goals

**Goals:**

- Un `.glb` por monstruo: malla + esqueleto + animaciones, importable.
- Verificación visual: bind pose sana + animación que dobla
  articulaciones sin explotar (3+ frames capturados).
- Integración mínima que no rompa el slice (colisión y lógica intactas).

**Non-Goals:**

- Retarget entre esqueletos distintos (cada modelo usa su `.chr`).
- `walk`/`attack` cableados (solo `stand` loop + `die` una vez).
- Texturas (siguen pendientes; mallas en gris).
- NPCs/jugador con modelo (solo monstruos).

## Decisions

- **Joints = índices `.chr` directos** (`usebones[matIdx//3]` verificado
  por anatomía: brazo izq. de Rangda). Alternativa: índice crudo —
  descartada (da columna/cadera para un brazo).
- **Matrices traspuestas** (row-major D3D → column-major glTF):
  `m2` a nodos, `m1` a IBMS. Alternativa: tal cual — descartada; el
  ensamblado estático ya validó el orden.
- **Quats `.ani` tal cual (x,y,z,w) con conjugado pendiente de la
  captura**: si la animación espeja, sigue leyéndose bien en MVP y se
  documenta. 30 fps asumidos (velocidad a ojo).
- **Colisión cápsula intacta + cápsula si falta modelo**: la lógica de
  caza no depende del arte.
- **`model` en `monsters.json`**: los datos mandan qué se ve; el
  validador comprueba que el `.chr` existe en el cliente (no el `.glb`,
  que es derivado).

## Risks / Trade-offs

- [Riesgo] Animación espejada o ejes cruzados → Mitigación: captura
  multi-frame; si dobla articulaciones se acepta documentado.
- [Riesgo] Curaduría fea (liebre que parece golem) → Mitigación: captura
  previa de candidatos; lore nuevo, vale cualquiera coherente en tamaño.
- [Riesgo] `.glb` pesados en repo → Mitigación: no se versionan;
  `setup_models.py` los deriva.

## Migration Plan

No aplica. Rollback = revert.

## Open Questions

- ¿30 fps es la velocidad real? A ojo en captura; afinar con testers.
