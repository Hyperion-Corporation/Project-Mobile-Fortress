describe('theme toggle', () => {
  it('toggles the theme control if present', () => {
    cy.visit('/');
    cy.get('body').then(($body) => {
      const btn = $body.find('button[aria-label*="Switch to"]');
      if (btn.length) {
        cy.wrap(btn.first()).click();
      }
    });
  });
});
