# Design: aethermere-lnd

## Reconocimiento (2026-09-18, `~/flyff-work/extracted/app/World/WdMadrigal/`)

- 900 tiles `WdMadrigalXX-YY.lnd` (malla 30×30). 641 comparten 200477 B;
  el resto forma una escalera con peldaños de 133124 B (= 2×66562) sobre
  bases de 133915/200477/267039/…: el tile lleva 0+ capas opcionales de
  ~66562 B (¿altura f32 129×129 = 66564 − 2 de conteo? ¿u8 258×258?).
- Cabecera: `u32 3` + 12 B cero + serie de `f32 3000.0` (¿tamaño de mundo
  o escala?). Sin lector C++ local (o3d-reader es solo modelos); el
  `.lnd` no está en el repo de referencia a primer vistazo.

## Enfoque (igual que `.o3d`: empírico + cuadre)

1. `lnd_parser.py`: vuelca cabecera (u32/f32 en varios offsets), busca
   rachas de f32 plausibles (alturas ~±500) y prueba dimensiones candidatas
   (129², 257², 258²…) por continuidad de filas; fija el layout por el que
   cuadre en batch + continuidad de bordes entre tiles vecinos.
2. `lnd_to_glb.py`: reutiliza el escritor GLB mínimo de `o3d_to_glb.py`
   (pos/normal/uv/índices, 1 material). Normales por diferencias finitas,
   UV 0..1 por tile.
3. `setup_terrain.py`: convierte los tiles del área de juego. El encaje
   mundo↔tile sale del RE (nombre `XX-YY` + origen/escala de cabecera);
   primera versión: malla combinada de N×N tiles en torno al spawn con
   desplazamiento para que el spawn quede sobre ella.
4. Godot (`main.tscn` + `main.gd` o script de terreno): `MeshInstance3D` +
   `StaticBody3D` trimesh desde `res://models/terrain_*.glb` si existen
   (`ResourceLoader.exists`, como monstruos); si no, el `Ground` actual.
   Sin cambios de físicas del jugador (la gravedad lo asienta).

## Alternativas descartadas

- Cazar el loader C++ en el repo de referencia: posible repliegue si el RE
  se atasca (pistas: `LibrarySource/common|resource`, `Neuz` no lo trae).
- Terreno procedural propio: pierde contra el real si el RE cuaja; queda
  como plan B (heightmap de ruido + misma integración).

## Verificación

- Batch 900/900 + informe de continuidad; `docs/lnd-research.md`.
- Importación en proyecto scratch sin errores + captura in-game con relieve
  + `SIM-QUEST PASS` + prueba en navegador (suelo visible, sin caídas).
