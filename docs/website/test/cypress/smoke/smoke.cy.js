describe('smoke', () => {
  it('loads the site root without a blank body', () => {
    cy.visit('/');
    cy.get('body').should('not.be.empty');
  });
});
