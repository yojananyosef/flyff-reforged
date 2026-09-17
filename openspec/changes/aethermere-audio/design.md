## Context

`aethermere-gameplay` está archivada en specs estables. El repo no
versiona binarios del cliente; `godot_project/audio/` se genera por
desarrollador con `setup_audio.py`. Nombres de archivo originales FlyFF
se mantienen como identificadores internos (no son texto visible).

## Goals / Non-Goals

**Goals:**

- Zona con identidad sonora, combate con feedback, UI que responde.
- Degradación elegante: sin archivos de audio, todo sigue funcionando.
- Verificación headless del cableado (archivos presentes + llamadas sin error).

**Non-Goals:**

- Música por zona múltiple (solo `ironhold`; el sistema ya acepta más).
- Audio posicional/3D (todo 2D; propuesta posterior si hace falta).
- Mezcla fina ni opciones de volumen persistentes (mute + niveles fijos).

## Decisions

- **Autoload `audio_manager` con 3 reproductores** (música, sting, SFX
  polifónico ×8) y buses `Music`/`SFX` creados por código. Alternativa:
  nodos en la escena — descartada; el audio debe sobrevivir a cambios
  de escena y ser llamable desde cualquier script.
- **Sting interrumpe música y la reanuda** vía señal `finished`.
  Alternativa: segundo bus permanente — descartada; complica la mezcla
  para un MVP.
- **Música de combate por temporizador** (6 s desde la última agresión,
  `notify_combat()`): simple y sin acoplar IA. Alternativa: estado de
  combate global — descartada por ahora; el temporizador basta.
- **Mute con M + niveles fijos** (música −10 dB, SFX −4 dB). Alternativa:
  menú de opciones — fuera de scope; el mute cubre la necesidad base.

## Risks / Trade-offs

- [Riesgo] Falta `audio/` y el juego va mudo sin que se note →
  Mitigación: aviso en consola al arrancar + fallo explícito en el sim.
- [Riesgo] Nombres de archivo del cliente cambian entre versiones →
  Mitigación: `setup_audio.py` falla en voz alta si falta alguno; el
  mapa vive en un solo sitio (script + `audio_manager` por nombre lógico).

## Migration Plan

No aplica. Rollback = revert del commit.

## Open Questions

- Ninguna abierta; volúmenes finos cuando haya testers.
