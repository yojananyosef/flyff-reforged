## Purpose

Sonorizar el slice jugable con assets del cliente: música de zona y
combate, stings de misión/nivel/muerte y SFX de combate e interfaz,
con degradación elegante si faltan los archivos.

## ADDED Requirements

### Requirement: Setup de audio por desarrollador

El script SHALL copiar los 16 archivos mapeados del cliente a
`godot_project/audio/{music,sfx}/` e imprimir resumen; la carpeta SHALL
estar gitignorada y el juego SHALL arrancar en silencio si falta.

#### Scenario: Setup local

- **WHEN** se ejecuta `setup_audio.py --client <app> --out godot_project/audio`
- **THEN** existen 16 archivos y el resumen dice `16/16`, y con la
  carpeta borrada el juego arranca con aviso y sin errores

### Requirement: Gestor de audio

El autoload SHALL exponer `play_sfx(nombre)`, `play_sting(nombre)`,
`play_zone_music()`, `notify_combat()`, `toggle_mute()`; la música de
zona SHALL sonar en loop al arrancar y el tema de combate SHALL sonar
6 s tras agresión; M SHALL alternar mute.

#### Scenario: Música reactiva

- **WHEN** hay agresión y pasan 6 s sin más
- **THEN** el reproductor de música vuelve al tema de la zona

### Requirement: Cableado a gameplay

Ataque, impacto, herida, muerte de monstruo, herida/muerte/nivel del
jugador, aceptar/completar misión, abrir/cerrar/opción de diálogo,
abrir/cerrar inventario y loot SHALL emitir su sonido sin errores.

#### Scenario: Caza con sonido

- **WHEN** el jugador mata a `mon_002` en la simulación
- **THEN** se emiten swing, hit, herida y muerte sin errores y el sim
  sigue en PASS
