const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:5173',
    supportFile: false,
    specPattern: [
      'test/cypress/e2e/**/*.cy.js',
      'test/cypress/smoke/**/*.cy.js',
    ],
    video: false,
  },
});
