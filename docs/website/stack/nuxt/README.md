# stack/nuxt/

Nuxt 3 **configuration package** for the documentation website — the Vue counterpart to
`github-pages/stack/next/`.

| Path | Role |
| --- | --- |
| `nuxt.config.ts` | Canonical Nuxt config (static Nitro preset, base URL) |
| `package.json` | Optional isolated Nuxt dependency set for experiments |
| `../../nuxt.config.ts` | Root re-export (discovery, same pattern as `eslint.config.js`) |

## Relationship to the Vite SPA

| Surface | Framework | Role |
| --- | --- | --- |
| `docs/website/` (parent) | Vite + Vue + Vue Router | Primary design hub + Markdown docs portal |
| `docs/website/stack/nuxt/` (this dir) | Nuxt 3 config | Nuxt/static multi-framework experiments |

This directory intentionally does **not** mirror the Vite website root (`app.vue`, `pages/`,
shared styles). When you need a Nuxt app shell, add Nuxt-only routes under a Nuxt project
root or extend this package — keep the Vite SPA as the product surface.

## Usage

```bash
# Config is re-exported at docs/website/nuxt.config.ts
cd docs/website/stack/nuxt
npm install
# Point Nuxt CLI at the parent (root re-export) or this package as needed:
#   cd docs/website && npx nuxt dev
```

ESLint for the parent website lives in `../eslint/`.
