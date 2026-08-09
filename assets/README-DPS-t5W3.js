const n=`# stack/nuxt/

Nuxt 3 **configuration** for the documentation website — the Vue counterpart to
\`github-pages/stack/next/\`.

| Path | Role |
| --- | --- |
| \`nuxt.config.ts\` | Canonical Nuxt config (static Nitro preset, base URL) |
| \`../../nuxt.config.ts\` | Root re-export (discovery, same pattern as \`eslint.config.js\`) |

Dependencies and scripts live on the parent website package (\`docs/website/package.json\`),
not in this directory.

## Relationship to the Vite SPA

| Surface | Framework | Role |
| --- | --- | --- |
| \`docs/website/\` (parent) | Vite + Vue + Vue Router | Primary design hub + Markdown docs portal |
| \`docs/website/stack/nuxt/\` (this dir) | Nuxt 3 config | Nuxt/static multi-framework experiments |

This directory intentionally does **not** mirror the Vite website root (\`app.vue\`, \`pages/\`,
shared styles). When you need a Nuxt app shell, add Nuxt-only routes under a Nuxt project
root or extend this config — keep the Vite SPA as the product surface.

## Usage

From the **repo root** (npm workspaces):

\`\`\`bash
npm run nuxt:prepare   # generate .nuxt types
npm run nuxt:dev
npm run nuxt:generate  # static output
npm run nuxt:build
npm run nuxt:preview
\`\`\`

Or from \`docs/website/\`:

\`\`\`bash
npm run nuxt:dev
# …
\`\`\`

Config is re-exported at \`docs/website/nuxt.config.ts\` → \`stack/nuxt/nuxt.config.ts\`.

ESLint for the parent website lives in \`../eslint/\`.
`;export{n as default};
