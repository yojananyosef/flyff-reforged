## Context

Specs estables: el juego arranca desde `res://` con repliegues
(`res://data/` si falta `../data`, silencio sin audio, cápsulas sin
modelos). Godot 4.7.2 + templates instalados (incl. `web_nothreads`).
Render GL Compatibility (compatible web).

## Goals / Non-Goals

**Goals:**

- Enlace jugable sin headers especiales (nothreads).
- Build reproducible con un comando + deploy documentado.
- El juego web carga datos, audio, texturas y modelos empaquetados.

**Non-Goals:**

- CI automático (manual por ahora; workflow después si hace falta).
- Móvil/táctil (teclado+ratón como en desktop).
- Música antes del primer clic (los navegadores exigen gesto).

## Decisions

- **`thread_support=false`**: GitHub Pages no envía COOP/COEP;
  el template nothreads corre sin ellos. Alternativa: Cloudflare
  con headers — descartada; Pages basta.
- **Staging de `data/` dentro del proyecto solo durante el build**:
  el export empaqueta `res://`; fuera del build no se duplica nada.
- **`export_presets.cfg` generado, no versionado** (ya gitignorado):
  evita rutas absolutas locales en el repo.
- **Rama `gh-pages` solo-artefactos** en vez de `/docs`: separa código
  de build y permite Pages por rama.

## Risks / Trade-offs

- [Riesgo] Template con threads por defecto y pantalla de error en web →
  Mitigación: se verifica en el log que usa `web_nothreads_release`.
- [Riesgo] `.pck` pesado (modelos+audio) tarda en cargar →
  Mitigación: se reporta el tamaño; carga progresiva ya la da Godot.
- [Riesgo] Usuario debe activar Pages en settings → Mitigación: README
  con los 3 clics.

## Migration Plan

No aplica. Rollback = borrar rama.

## Open Questions

- Ninguna.
