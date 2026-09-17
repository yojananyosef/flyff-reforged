# Investigación del formato .o3d (modelos 3D FlyFF v21)

Estado: header resuelto, cuerpo pendiente. Documento vivo — actualizar a
medida que avance el reverse engineering.

## Fuente de referencia

Lector C++ comunitario: `~/flyff-work/o3d-reader/FlyFFO3DReader-OPENGL/`
(`LoadedObject.cpp::LoadObject`, `CMotion.cpp`, `Utils.h`). No se copia ese
código; aquí solo se resume el formato observado para reimplementarlo en Python.

## Header (resuelto, verificado en 6202 archivos)

```text
u8  name_len         # longitud del nombre interno (sin contar +4, ver nota)
u8[name_len] nombre  # XOR 0xCD byte a byte
u32 version          # 21 o 22 (clientes v21)
u32 id/hash          # serial ID
vec3 force1, force2  # vectores de fuerza (12+12 bytes)
[si version >= 22: vec3 force3, force4]
f32 scroll_u, scroll_v
16 bytes reservados (zeros)
vec3 bb_min, bb_max  # bounding box
f32 per_slerp
u32 max_frame        # frames de animacion embebida (0 = estatico)
u32 max_event (+ eventos si > 0)
u32 coll_flag        # si != 0: GMOBJECT de colision embebido
[u32 lod_flag]
u32 bone_count       # si > 0: huesos base (mat4 x2 cada uno) + ReadTM si max_frame > 0
u32 pool_size        # objetos geometricos
por grupo LOD: u32 obj_count + objetos...
```

Nota: el lector C++ lee `cLen` (1 byte) y luego `cLen` bytes con XOR `0xCD`.
El plan original decía "byte 0 = filename_len + 4"; en la práctica `cLen`
ya es la longitud exacta del nombre.

Versiones observadas: `VER_MESH = 20` mínimo aceptado; archivos reales en
21 y 22. Coherente con cliente v21.

## Cuerpo (pendiente)

Después del header:

1. Los primeros ~100 bytes tras `id/hash` son zeros en modelos pequeños
   (reservados + bounding box de modelos sin colisión).
2. Cada `GMOBJECT` (`LoadGMObject`): `bb_min/max`, flags
   (`opacity/bump/rigid` + 28 bytes skip), conteos
   (`vertex_list/vb/face_list/ib`), buffers de vértices (`SKINVERTEX` 40 bytes
   o `NORMALVERTEX` 32 bytes), índices `u16`, vértices physique opcionales,
   materiales (`GLWMATERIAL9` 68 bytes + nombre de textura) y bloques de material.
3. Objetos `GMT_SKIN` llevan pesos (`w1/w2/matIdx`); `GMT_NORMAL` son rígidos.
4. Si `max_frame > 0`, cada objeto normal lleva su `TM_ANIMATION` embebido
   (`LoadTMAni`: flag + frames de 28 bytes, igual que `.ani`).

## Estrategia de parser Python (Fase 2)

1. Reutilizar lectura de header + `ReadTM` ya validados en `chr_parser.py` /
   `ani_parser.py` (mismo `TM_ANIMATION` de 28 bytes).
2. Implementar `LoadGMObject` paso a paso con un modo verbose que vuelque
   offsets, validando `vertex_count` e `index_count` contra el tamaño restante.
3. Exportar a `.glb` con `pygltflib` (vértices + normales + UV + índices +
   materiales con textura `.dds`).
4. El MVP no bloquea por esto: la base Godot usa placeholders hasta la Fase 5.

## Preguntas abiertas

- [ ] Tamaños exactos de `SKINVERTEX` con bump (`SKINVERTEX_BUMP` vs normal).
- [ ] Significado de `m_bSendVS` tras los huesos base.
- [ ] Estructura de `LOD_GROUP` con `m_bLOD = 1` (pocos modelos la usan).
- [ ] Atributos `MOTION_ATTR` finales cuando `nAttr == max_frame` (versión ≥ 21).

## Archivos de prueba

- `Model/Ctrl_ArenaTransparentwall01.o3d` (pequeño, probablemente sin huesos).
- `Model/Part_cloChameleon1.o3d` (parte de armadura, con skin).
- Cualquiera de los 6202 `.o3d` en `assets/models_raw/` tras extraer.
