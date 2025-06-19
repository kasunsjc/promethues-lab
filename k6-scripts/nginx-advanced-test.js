import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const timeToFirstByte = Trend('time_to_first_byte');
const contentSize = Trend('content_size');

// Options
export const options = {
  scenarios: {
    // Common user behavior
    average_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 20 },  // Ramp up to 20 users
        { duration: '3m', target: 20 },  // Stay at 20 users for 3 minutes
        { duration: '1m', target: 0 },   // Ramp down to 0
      ],
      gracefulRampDown: '30s',
    },
    // Spike test
    spike_test: {
      executor: 'ramping-vus',
      startTime: '5m30s',  // Start after the average load test
      startVUs: 0,
      stages: [
        { duration: '30s', target: 50 }, // Quick ramp-up to 50 users
        { duration: '1m', target: 50 },  // Stay at 50 users for 1 minute
        { duration: '30s', target: 0 },  // Quick ramp-down to 0
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    errors: ['rate<0.1'],            // Error rate should be less than 10%
    'time_to_first_byte': ['p(95)<300'], // 95% of TTFB should be below 300ms
    'http_req_failed': ['rate<0.05'],   // HTTP errors should be less than 5%
  },
};

const BASE_URL = 'http://nginx:80';

export default function () {
  group('Static content', function () {
    // Request the home page
    const homePage = http.get(`${BASE_URL}/`);
    
    // Check if status was 200 OK
    const homeSuccess = check(homePage, {
      'home page status is 200': (r) => r.status === 200,
    });
    
    // Record metrics
    errorRate.add(!homeSuccess);
    timeToFirstByte.add(homePage.timings.waiting);
    contentSize.add(homePage.body.length);
    
    sleep(randomIntBetween(1, 3));
    
    // Request static assets (images, css, js, etc)
    const paths = [
      '/assets/style.css',
      '/assets/image.jpg',
      '/assets/script.js',
    ];
    
    // Some of these paths might not exist, but that's ok for load testing
    const randomPath = paths[Math.floor(Math.random() * paths.length)];
    const staticContent = http.get(`${BASE_URL}${randomPath}`);
    
    // Even if 404, we're still testing the server response
    timeToFirstByte.add(staticContent.timings.waiting);
  });
  
  // Simulate heavy requests
  group('Heavy requests', function () {
    // 20% chance to execute this block
    if (Math.random() < 0.2) {
      // Simulate heavy operations
      const response = http.get(`${BASE_URL}/heavy`);
      timeToFirstByte.add(response.timings.waiting);
    }
  });
  
  sleep(randomIntBetween(1, 5));
}
