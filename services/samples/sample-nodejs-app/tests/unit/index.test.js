const request = require('supertest');
const app = require('../../src/index');

describe('API Endpoints', () => {
  describe('GET /', () => {
    it('should return service information', async () => {
      const res = await request(app).get('/');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('service', 'sample-nodejs-app');
      expect(res.body).toHaveProperty('status', 'running');
      expect(res.body).toHaveProperty('version');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'UP');
      expect(res.body).toHaveProperty('service', 'sample-nodejs-app');
    });
  });

  describe('GET /ready', () => {
    it('should return readiness status', async () => {
      const res = await request(app).get('/ready');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('status', 'READY');
      expect(res.body).toHaveProperty('service', 'sample-nodejs-app');
    });
  });

  describe('GET /info', () => {
    it('should return service details', async () => {
      const res = await request(app).get('/info');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('name', 'sample-nodejs-app');
      expect(res.body).toHaveProperty('description');
      expect(res.body).toHaveProperty('version', '0.1.0');
    });
  });

  describe('GET /metrics', () => {
    it('should return prometheus metrics', async () => {
      const res = await request(app).get('/metrics');
      expect(res.statusCode).toBe(200);
      expect(res.text).toContain('# HELP');
    });
  });
});
