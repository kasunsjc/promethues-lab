import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { randomIntBetween, randomItem } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const timeToFirstByte = Trend('time_to_first_byte');
const contentSize = Trend('content_size');
const apiCalls = new Counter('api_calls_total');
const dbConnections = new Counter('db_connections');

// Test scenarios based on intensity
const testIntensity = __ENV.TEST_INTENSITY || 'light';

const getScenarioConfig = (intensity) => {
  const configs = {
    light: {
      normal_load: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
          { duration: '1m', target: 10 },
          { duration: '2m', target: 10 },
          { duration: '1m', target: 0 },
        ],
      },
      spike_test: {
        executor: 'ramping-vus',
        startTime: '4m30s',
        startVUs: 0,
        stages: [
          { duration: '30s', target: 25 },
          { duration: '1m', target: 25 },
          { duration: '30s', target: 0 },
        ],
      },
    },
    medium: {
      normal_load: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
          { duration: '2m', target: 25 },
          { duration: '5m', target: 25 },
          { duration: '2m', target: 0 },
        ],
      },
      spike_test: {
        executor: 'ramping-vus',
        startTime: '9m30s',
        startVUs: 0,
        stages: [
          { duration: '1m', target: 75 },
          { duration: '2m', target: 75 },
          { duration: '1m', target: 0 },
        ],
      },
    },
    heavy: {
      normal_load: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
          { duration: '3m', target: 50 },
          { duration: '10m', target: 50 },
          { duration: '3m', target: 0 },
        ],
      },
      spike_test: {
        executor: 'ramping-vus',
        startTime: '16m30s',
        startVUs: 0,
        stages: [
          { duration: '2m', target: 150 },
          { duration: '3m', target: 150 },
          { duration: '2m', target: 0 },
        ],
      },
    },
  };
  return configs[intensity];
};

export const options = {
  scenarios: getScenarioConfig(testIntensity),
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.1'],
    'time_to_first_byte': ['p(95)<300'],
    'http_req_failed': ['rate<0.05'],
  },
};

const BASE_URL = 'http://nginx:80';

// Simulated user journey patterns
const userJourneys = [
  'homepage_browser',
  'static_content_consumer',
  'heavy_content_user',
  'api_user',
];

export default function () {
  const userType = randomItem(userJourneys);
  
  group(`User Journey: ${userType}`, function () {
    switch (userType) {
      case 'homepage_browser':
        homepageBrowsing();
        break;
      case 'static_content_consumer':
        staticContentConsumption();
        break;
      case 'heavy_content_user':
        heavyContentUsage();
        break;
      case 'api_user':
        apiUsage();
        break;
    }
  });
}

function homepageBrowsing() {
  group('Homepage browsing', function () {
    const response = http.get(`${BASE_URL}/`);
    
    const success = check(response, {
      'homepage status is 200': (r) => r.status === 200,
      'homepage contains expected content': (r) => r.body.includes('html'),
    });
    
    errorRate.add(!success);
    timeToFirstByte.add(response.timings.waiting);
    contentSize.add(response.body.length);
    
    sleep(randomIntBetween(2, 5));
  });
}

function staticContentConsumption() {
  group('Static content consumption', function () {
    const assets = [
      '/assets/style.css',
      '/assets/script.js',
      '/favicon.ico',
    ];
    
    assets.forEach(asset => {
      const response = http.get(`${BASE_URL}${asset}`);
      timeToFirstByte.add(response.timings.waiting);
      
      if (response.status !== 404) {
        contentSize.add(response.body.length);
      }
    });
    
    sleep(randomIntBetween(1, 3));
  });
}

function heavyContentUsage() {
  group('Heavy content usage', function () {
    // 30% chance for heavy content
    if (Math.random() < 0.3) {
      const response = http.get(`${BASE_URL}/heavy.html`);
      
      const success = check(response, {
        'heavy content accessible': (r) => r.status === 200 || r.status === 404,
      });
      
      errorRate.add(!success);
      timeToFirstByte.add(response.timings.waiting);
      
      if (response.status === 200) {
        contentSize.add(response.body.length);
      }
      
      sleep(randomIntBetween(3, 8));
    }
  });
}

function apiUsage() {
  group('API usage simulation', function () {
    // Simulate API calls by accessing different endpoints
    const endpoints = [
      '/',
      '/health',
      '/status',
      '/info',
    ];
    
    const endpoint = randomItem(endpoints);
    const response = http.get(`${BASE_URL}${endpoint}`);
    
    apiCalls.add(1);
    timeToFirstByte.add(response.timings.waiting);
    
    // Simulate database connection overhead
    if (Math.random() < 0.1) {
      dbConnections.add(1);
      sleep(randomIntBetween(0.1, 0.5));
    }
    
    sleep(randomIntBetween(1, 4));
  });
}

export function handleSummary(data) {
  return {
    'performance-summary.json': JSON.stringify(data, null, 2),
    'performance-report.html': generateHTMLReport(data),
  };
}

function generateHTMLReport(data) {
  const template = `
<!DOCTYPE html>
<html>
<head>
    <title>k6 Performance Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { margin: 10px 0; padding: 10px; border-left: 4px solid #007acc; }
        .pass { border-left-color: #28a745; }
        .fail { border-left-color: #dc3545; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🔥 k6 Performance Test Report</h1>
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Test Duration:</strong> ${data.metrics.iteration_duration.avg.toFixed(2)}s average per iteration</p>
        <p><strong>Total Requests:</strong> ${data.metrics.http_reqs.count}</p>
        <p><strong>Failed Requests:</strong> ${data.metrics.http_req_failed.count}</p>
        <p><strong>Error Rate:</strong> ${(data.metrics.http_req_failed.rate * 100).toFixed(2)}%</p>
    </div>
    
    <h2>Key Metrics</h2>
    <table>
        <tr><th>Metric</th><th>Average</th><th>95th Percentile</th><th>Status</th></tr>
        <tr><td>Response Time</td><td>${data.metrics.http_req_duration.avg.toFixed(2)}ms</td><td>${data.metrics.http_req_duration['p(95)'].toFixed(2)}ms</td><td>${data.metrics.http_req_duration['p(95)'] < 500 ? '✅' : '❌'}</td></tr>
        <tr><td>Time to First Byte</td><td>${data.metrics.time_to_first_byte?.avg?.toFixed(2) || 'N/A'}ms</td><td>${data.metrics.time_to_first_byte?.['p(95)']?.toFixed(2) || 'N/A'}ms</td><td>${(data.metrics.time_to_first_byte?.['p(95)'] || 0) < 300 ? '✅' : '❌'}</td></tr>
        <tr><td>Error Rate</td><td colspan="2">${(data.metrics.errors?.rate * 100 || 0).toFixed(2)}%</td><td>${(data.metrics.errors?.rate || 0) < 0.1 ? '✅' : '❌'}</td></tr>
    </table>
    
    <h2>Detailed Metrics</h2>
    <pre>${JSON.stringify(data.metrics, null, 2)}</pre>
</body>
</html>`;
  
  return template;
}
