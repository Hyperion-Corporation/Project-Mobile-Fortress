# eslint/

ESLint configuration for the documentation website (Vue 3 + TypeScript).

| File | Role |
| --- | --- |
| `eslint.config.js` | Flat config (ESLint 9): `eslint-plugin-vue` + TypeScript |

## Usage

From `docs/website/`:

```bash
npm run lint
# or
npx eslint -c eslint/eslint.config.js .
```
