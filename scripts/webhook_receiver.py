#!/usr/bin/env python3
"""
Simple webhook receiver for testing Alertmanager notifications.
This script creates a basic HTTP server that receives and logs alerts.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import datetime

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            alert_data = json.loads(post_data.decode('utf-8'))
            timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            print(f"\n[{timestamp}] Received alert:")
            print(f"Path: {self.path}")
            print(f"Headers: {dict(self.headers)}")
            print(f"Data: {json.dumps(alert_data, indent=2)}")
            
            # Extract alert information
            if 'alerts' in alert_data:
                for alert in alert_data['alerts']:
                    print(f"  Alert: {alert.get('labels', {}).get('alertname', 'Unknown')}")
                    print(f"  Status: {alert.get('status', 'Unknown')}")
                    print(f"  Instance: {alert.get('labels', {}).get('instance', 'Unknown')}")
                    print(f"  Summary: {alert.get('annotations', {}).get('summary', 'No summary')}")
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status": "success"}')
            
        except Exception as e:
            print(f"Error processing webhook: {e}")
            self.send_response(400)
            self.end_headers()

    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == '__main__':
    server = HTTPServer(('localhost', 5001), WebhookHandler)
    print("Webhook receiver running on http://localhost:5001")
    print("Press Ctrl+C to stop")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down webhook receiver")
        server.shutdown()
