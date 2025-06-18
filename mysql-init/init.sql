-- Create a sample table with some data
USE sample_db;

-- Create a sample_table with various data types
CREATE TABLE IF NOT EXISTS sample_table (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  value INT,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some sample data
INSERT INTO sample_table (name, value, description) VALUES
  ('Item A', 100, 'This is a description for Item A'),
  ('Item B', 200, 'This is a description for Item B'),
  ('Item C', 150, 'This is a description for Item C'),
  ('Item D', 300, 'This is a description for Item D'),
  ('Item E', 250, 'This is a description for Item E');

-- Create a table for monitoring purposes
CREATE TABLE IF NOT EXISTS metrics_test (
  id INT AUTO_INCREMENT PRIMARY KEY,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  metric_name VARCHAR(100),
  metric_value DOUBLE,
  labels JSON
);

-- Insert some test metrics
INSERT INTO metrics_test (metric_name, metric_value, labels) VALUES
  ('cpu_usage', 45.5, '{"server": "app-server-1", "environment": "production"}'),
  ('memory_usage', 65.2, '{"server": "app-server-1", "environment": "production"}'),
  ('disk_usage', 78.9, '{"server": "app-server-1", "environment": "production"}'),
  ('cpu_usage', 30.2, '{"server": "app-server-2", "environment": "staging"}'),
  ('memory_usage', 45.1, '{"server": "app-server-2", "environment": "staging"}'),
  ('disk_usage', 50.3, '{"server": "app-server-2", "environment": "staging"}');
