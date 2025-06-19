import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Options
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users in 30 seconds
    { duration: '1m', target: 50 },   // Ramp up to 50 users over 1 minute
    { duration: '2m', target: 50 },   // Stay at 50 users for 2 minutes
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    errors: ['rate<0.1'],            // Error rate should be less than 10%
  },
};

export default function () {
  // Make a GET request to the Nginx service
  const response = http.get('http://nginx:80/');
  
  // Check if the response was successful
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
  });
  
  // If the check failed, increment the error rate
  errorRate.add(!success);
  
  // Sleep for a random time between 1s and 5s before making the next request
  sleep(Math.random() * 4 + 1);
}
