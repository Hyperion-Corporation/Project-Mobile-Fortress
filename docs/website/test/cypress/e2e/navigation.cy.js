describe('navigation', () => {
  it('loads the design hub and shows the brand', () => {
    cy.visit('/');
    cy.contains('Mobile Fortress').should('be.visible');
  });

  it('can open the documentation portal', () => {
    cy.visit('/');
    cy.contains('a', 'Documentation').click();
    cy.location('pathname').should('not.eq', '/');
  });
});
