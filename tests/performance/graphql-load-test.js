// =============================================================================
// FILE: tests/performance/graphql-load-test.js
// PURPOSE: k6 load test for Hasura GraphQL API
//          Tests query performance and verifies P95 < 1s
// USAGE: k6 run tests/performance/graphql-load-test.js
// =============================================================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const queryDuration = new Trend('query_duration');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users
    { duration: '1m', target: 50 },   // Ramp up to 50 users
    { duration: '2m', target: 50 },   // Stay at 50 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(95)<1000'],  // P95 should be < 1s
    'errors': ['rate<0.1'],                // Error rate should be < 10%
  },
};

// Environment variables
const HASURA_HOST = __ENV.HASURA_HOST || 'hasura.local';
const HASURA_ADMIN_SECRET = __ENV.HASURA_ADMIN_SECRET || 'fawkes-hasura-admin-secret-dev-changeme';
const GRAPHQL_ENDPOINT = `http://${HASURA_HOST}/v1/graphql`;

// GraphQL queries to test
const queries = {
  // Simple query
  introspection: {
    query: '{ __typename }',
  },
  
  // Schema query
  schema: {
    query: '{ __schema { queryType { name } } }',
  },
};

// Request headers
const headers = {
  'Content-Type': 'application/json',
  'x-hasura-admin-secret': HASURA_ADMIN_SECRET,
};

export default function () {
  // Select a random query
  const queryNames = Object.keys(queries);
  const randomQuery = queryNames[Math.floor(Math.random() * queryNames.length)];
  const query = queries[randomQuery];
  
  // Make GraphQL request
  const response = http.post(
    GRAPHQL_ENDPOINT,
    JSON.stringify(query),
    { headers }
  );
  
  // Check response
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'has data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.data !== undefined && body.errors === undefined;
      } catch (e) {
        return false;
      }
    },
    'response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  // Record metrics
  errorRate.add(!success);
  queryDuration.add(response.timings.duration);
  
  // Think time
  sleep(1);
}

// Setup function - runs once before test
export function setup() {
  console.log('Starting GraphQL load test...');
  console.log(`Endpoint: ${GRAPHQL_ENDPOINT}`);
  console.log(`Target: P95 < 1s`);
  
  return {
    startTime: new Date().toISOString(),
  };
}

// Teardown function - runs once after test
export function teardown(data) {
  console.log(`Test started at: ${data.startTime}`);
  console.log(`Test ended at: ${new Date().toISOString()}`);
  console.log('Load test completed!');
}
