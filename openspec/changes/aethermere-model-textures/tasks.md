## 1. Conversor con texturas

- [x] 1.1 `o3d_to_skinglb.py --tex-dir`: lookup `<base>.png`
  insensible a mayúsculas por `extras.flyff_texture`; embebe
  `images`/`samplers`/`textures` y `baseColorTexture` (TEXCOORD_0);
  aviso + blanco si falta
- [x] 1.2 `setup_models.py` y `setup_player_model.py` propagan
  `--tex-dir` a `o3d_to_skinglb.py`

## 2. Orquestación y regeneración

- [x] 2.1 `setup_model_textures.py`: extrae `.dds` (sueltos
  `Model/Texture/` + `part_mTex.res` vía `res_parser`), convierte a
  PNG temporal (PIL, RGBA) y regenera los 6 `.glb` con `--tex-dir`
- [x] 2.2 Regenerar `PlayerMvr.glb` + 5 monstruos y verificar pintura
  embebida (images/textures en el JSON del `.glb`)

## 3. Verificación y cierre

- [x] 3.1 Captura en navegador (avatar de frente + monstruo; sin
  espejo vertical) + SIM-QUEST PASS
- [x] 3.2 `openspec validate aethermere-model-textures --strict` OK
- [ ] 3.3 Commit + push (+ rebuild web y deploy a gh-pages)
