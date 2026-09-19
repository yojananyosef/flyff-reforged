## 1. Conversor estático con texturas

- [x] 1.1 `o3d_to_glb.py --tex-dir`: lookup insensible a mayúsculas,
  embebe `images`/`samplers`/`textures` + `baseColorTexture`; aviso +
  blanco si falta (+ split por bloques de material y fix de caché)
- [x] 1.2 `setup_props.py`: tiendas `Obj_EliunTent01/02` + muro
  `Obj_BeheBasicwall01` (DDS sueltos → PNG temporal → `.glb`)

## 2. Colocación con colisión

- [x] 2.1 `zones.json ironhold.props`: 5 entradas (2 tiendas + 3
  tramos de muro) con `model`, `x`, `z`, `yaw`
- [x] 2.2 `main.gd _load_props()`: instancia + snap a `ground_height`
  + `create_trimesh_collision()`; repliegue sin `.glb`

## 3. Verificación y cierre

- [x] 3.1 Captura en navegador (campamento con tiendas/muros) +
  SIM-QUEST PASS (props presentes, colisión bloquea)
- [x] 3.2 `openspec validate aethermere-props --strict` OK
- [x] 3.3 Commit + push (+ rebuild web y deploy a gh-pages)
