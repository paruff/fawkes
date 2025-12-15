const { When, Then } = require('@cucumber/cucumber');
const request = require('supertest');
const app = require('../../../src/index');
const assert = require('assert');

let response;

When('I request the health endpoint', async function () {
  response = await request(app).get('/health');
});

When('I request the ready endpoint', async function () {
  response = await request(app).get('/ready');
});

When('I request the info endpoint', async function () {
  response = await request(app).get('/info');
});

Then('the response status should be {int}', function (statusCode) {
  assert.strictEqual(response.statusCode, statusCode);
});

Then('the response should contain status {string}', function (status) {
  assert.strictEqual(response.body.status, status);
});

Then('the response should contain service {string}', function (service) {
  assert.strictEqual(response.body.service, service);
});

Then('the response should contain name {string}', function (name) {
  assert.strictEqual(response.body.name, name);
});

Then('the response should contain version {string}', function (version) {
  assert.strictEqual(response.body.version, version);
});
