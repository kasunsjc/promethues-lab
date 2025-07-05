#!/bin/bash
# Quick validation script to test script organization

echo "🔧 Testing script organization..."

# Test root scripts
echo "📂 Testing root directory scripts..."
bash -n ./monitoring-helper.sh && echo "✅ monitoring-helper.sh syntax OK"
bash -n ./commands.sh && echo "✅ commands.sh syntax OK"

# Test scripts directory
echo "📂 Testing scripts/ directory scripts..."
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        bash -n "$script" && echo "✅ $(basename "$script") syntax OK"
    fi
done

# Test Python script
echo "📂 Testing Python scripts..."
python3 -m py_compile scripts/webhook_receiver.py && echo "✅ webhook_receiver.py syntax OK"

# Test config files exist
echo "📂 Testing config directory..."
[[ -f config/prometheus.yml ]] && echo "✅ prometheus.yml exists"
[[ -f config/alertmanager.yml ]] && echo "✅ alertmanager.yml exists"
[[ -f config/alert_rules.yml ]] && echo "✅ alert_rules.yml exists"
[[ -f config/security_rules.yml ]] && echo "✅ security_rules.yml exists"

echo "🎉 Script organization validation complete!"
