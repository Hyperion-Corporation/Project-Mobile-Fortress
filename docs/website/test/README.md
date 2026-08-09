# test/

Test harness for the Mobile Fortress docs website.

| Path | Role |
| --- | --- |
| `vitest.setup.ts` | Global Vitest setup (MSW + in-memory `localStorage`) |
| `unit/components/` | Component unit tests |
| `unit/utils/` | Utility unit tests |
| `integration/` | Multi-module tests + `mocks/` (MSW) |
| `cypress/e2e/` | Browser end-to-end flows |
| `cypress/smoke/` | Fast smoke specs |
| `cypress/cypress.config.js` | Cypress config (`baseUrl` defaults to Vite dev server) |

## Commands

From `docs/website/`:

```bash
npm test                 # unit + integration (Vitest)
npm run test:unit
npm run test:integration
npm run cypress:run      # requires `npm run dev` in another terminal
npm run cypress:smoke
```
