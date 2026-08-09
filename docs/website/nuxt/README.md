# nuxt/

Nuxt 3 package for the documentation website — the **Vue** counterpart to the
**Next.js** host used on React sites in this org (e.g. `github-pages/next/`).

| Path | Role |
| --- | --- |
| `nuxt.config.ts` | Nuxt config (static Nitro preset, base URL) |
| `app.vue` | Root Nuxt app shell |
| `pages/` | File-based routes (`pages/index.vue`) |
| `package.json` | Isolated Nuxt dependency set |

## Relationship to the Vite SPA

| Surface | Framework | Role |
| --- | --- | --- |
| `docs/website/` (parent) | Vite + Vue + Vue Router | Primary design hub + Markdown docs portal |
| `docs/website/nuxt/` (this dir) | Nuxt 3 | Nuxt/static multi-framework experiments |

## Usage

```bash
cd docs/website/nuxt
npm install
npm run dev        # Nuxt dev server
npm run generate   # static output under .output/public
```

ESLint for the parent website lives in `../eslint/`.
