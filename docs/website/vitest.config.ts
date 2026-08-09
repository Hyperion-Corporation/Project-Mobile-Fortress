import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: [fileURLToPath(new URL('./test/vitest.setup.ts', import.meta.url))],
    include: [
      'test/unit/**/*.{test,spec}.{ts,tsx}',
      'test/integration/**/*.{test,spec}.{ts,tsx}',
    ],
    globals: true,
  },
});
