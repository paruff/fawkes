module.exports = {
  default: {
    require: ['tests/bdd/step_definitions/**/*.js'],
    format: ['progress', 'html:test-results/cucumber-report.html', 'json:test-results/cucumber.json'],
    formatOptions: { snippetInterface: 'async-await' }
  }
};
