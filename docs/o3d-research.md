# Investigación del formato .o3d (modelos 3D FlyFF v21)

Estado: **resuelto y verificado** — parser completo (`scripts/parsers/o3d_parser.py`)
y conversor a `.glb` (`scripts/converters/o3d_to_glb.py`). Batch: **6201/6202
archivos cuadran al byte exacto** con índices en rango; 3 modelos importados
en Godot sin errores con capturas en `docs/o3d-proof/`.

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

## Cuerpo (resuelto)

Flujo `LoadObject` completo, verificado por cuadre exacto en batch:

1. `u32 coll_flag`: si != 0, un `GMOBJECT` de colisión (tipo NORMAL).
2. `u32 lod_flag` + `u32 bone_count`: huesos base (mat4 ×2 cada uno);
   si `max_frame > 0`, `ReadTM` (igual que `.ani`) + `u32 sendVS`.
3. `u32 pool_size` + 3 grupos si LOD, 1 si no; por grupo `u32 obj_count`.
4. Por objeto: `u32 ntype` (tipo = `& 0xFFFF`: 0 NORMAL, 1 SKIN, 2 BONE;
   luz = `& 0x80000000`), `useBone[]`, id, padre (−1 o tipo), mat4 local.
5. `LoadGMObject`: bbox, `opacity/bump/rigid` + 28 skip, conteos
   (`vertex_list/vb/face_list/ib`), `vertexList` (vec3), VB
   (**SKIN 44 B / NORMAL 32 B, el flag `bump` NO cambia el tamaño**),
   índices `u16` (IB + IIB), physique opcional, materiales
   (`GLWMATERIAL9` 68 B + nombre) y bloques (136 B).
6. Objetos NORMAL con `max_frame > 0` llevan `LoadTMAni` (flag + frames
   de 28 B). Al final, `nAttr` solo si quedan bytes (el lector C++ lee
   de más sin comprobar EOF).

Hallazgos:

- LOD = 3 grupos con la misma malla en 3 resoluciones; el conversor
  exporta el grupo 0 por defecto (`--group -1` = todos).
- `Part_femaleHead.o3d` no es `.o3d` (empieza con `10 00 00 00 B842...`,
  sin nombre XOR): única excepción del batch, queda fuera.
- Asunciones documentadas: `matIdx` = 2×u16 de huesos con pesos w1/w2;
  matrices volcadas tal cual (capturas confirman ensamblado correcto);
  Y-up coincide (alturas en Y, p. ej. Rangda 0–10.4 m).

## Estrategia de parser Python (completada)

1. ~~Reutilizar lectura de header + `ReadTM`...~~ Hecho en `o3d_parser.py`.
2. ~~Implementar `LoadGMObject` paso a paso...~~ Hecho y validado en batch.
3. ~~Exportar a `.glb` con `pygltflib`...~~ Hecho sin dependencias
   (`o3d_to_glb.py`): el MVP sigue con placeholders hasta la Fase 5,
   cuando se fusionarán esqueletos (huesos `.o3d` sin nombres + `.chr`)
   y se convertirán texturas `.dds`.

## Preguntas abiertas (Fase 5)

- [ ] Fusión esqueleto `.o3d` (sin nombres) + `.chr` para skinning animado.
- [ ] Conversor `.dds` → `.png` y materiales con textura en el `.glb`.
- [ ] `m_bSendVS` tras los huesos base (preservado, sin interpretar).
- [ ] `Part_femaleHead.o3d`: identificar su formato real.

## Archivos de prueba

- `Model/Ctrl_ArenaTransparentwall01.o3d` (pequeño, probablemente sin huesos).
- `Model/Part_cloChameleon1.o3d` (parte de armadura, con skin).
- Cualquiera de los 6202 `.o3d` en `assets/models_raw/` tras extraer.
