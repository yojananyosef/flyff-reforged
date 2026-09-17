## 1. Assets y setup

- [x] 1.1 `scripts/parsers/setup_audio.py` copia los 16 archivos (4 música + 12 SFX) del cliente a `godot_project/audio/` con resumen, verificado conteo 16/16
- [x] 1.2 `godot_project/audio/` gitignorado y arranque sin archivos muestra aviso pero no falla, verificado borrando la carpeta en `/tmp`

## 2. Gestor de audio

- [x] 2.1 Autoload `audio_manager` (música loop, sting con reanudación, SFX polifónico, buses, mute con M), verificado `check-only` + arranque sin errores
- [x] 2.2 Música de zona `ironhold` al arrancar y tema de combate 6 s tras agresión, verificado en sim que el stream cambia

## 3. Cableado

- [x] 3.1 Ataque/golpe/muerte/herida/nivel/muerte del jugador con SFX, verificado en sim (muerte de `mon_002` emite sin error)
- [x] 3.2 Aceptar/completar misión (sting), diálogo e inventario con sonidos UI, verificado en sim

## 4. Cierre

- [x] 4.1 `openspec validate aethermere-audio --strict` pasa sin errores
- [x] 4.2 Commit + push y repo remoto actualizado
