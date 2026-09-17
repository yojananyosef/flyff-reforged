## Why

El slice jugable es mudo: se extrajeron 51 temas y 1680 efectos del
cliente y ninguno suena. Sin música de zona, SFX de combate ni licencias
de UI, el juego se siente placeholder aunque la lógica funcione. Esta
propuesta integra una selección mínima (4 temas + 12 efectos) con un
gestor de audio propio.

## What Changes

- Script `setup_audio.py`: copia los 16 archivos elegidos del cliente a
  `godot_project/audio/` (carpeta gitignorada; cada dev la genera).
- Autoload `audio_manager`: música de zona en loop, tema de combate
  mientras haya agresión reciente, stings (misión, nivel, muerte),
  pool SFX polifónico, buses Music/SFX y mute con M.
- Cableado: ataque, golpe, herida, muerte, subida de nivel, aceptar y
  completar misión, diálogo, inventario y loot.
- Chequeos de audio en la simulación headless (`--sim-quest`).

## Capabilities

### New Capabilities

- `audio`: gestor de audio + mapa de assets + cableado a gameplay.

### Modified Capabilities

- `gameplay`: ataque, muerte, misiones, diálogo e inventario emiten sonido;
  la simulación verifica el audio.

## Impact

- `godot_project/audio/` no se versiona (binarios del cliente, ver
  `.gitignore`); sin esos archivos el juego arranca igual pero en
  silencio con un aviso.
- Sin cambios en `data/` ni en lógica de misiones/combate.
