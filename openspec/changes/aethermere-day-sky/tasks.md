## 1. Cielo diurno

- [x] 1.1 `main.tscn sky_env`: `background_mode = 2` + `Sky` con
  `ProceduralSkyMaterial` diurno + niebla sutil (`fog_sky_affect = 0`
  para que la niebla no tape el cielo)

## 2. Verificación y cierre

- [x] 2.1 Captura en navegador (horizonte claro, dunas fundidas) +
  SIM-QUEST PASS
- [x] 2.2 `openspec validate aethermere-day-sky --strict` OK
- [ ] 2.3 Commit + push (+ rebuild web y deploy a gh-pages)
