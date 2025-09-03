#!/bin/bash

# Health check monitoring script for TraderApi
# Runs health checks every 30 seconds

echo "Starting server health monitoring..."
echo "Press Ctrl+C to stop"

check_count=0
while true; do
    check_count=$((check_count + 1))
    echo ""
    echo "=== Health Check #$check_count at $(date) ==="
    
    # Check if server responds
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/swagger/index.html)
    response_time=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:5000/swagger/index.html)
    
    # Check process status
    pid=$(pgrep -f 'dotnet.*TraderApi' | head -1)
    
    if [ "$response" == "200" ]; then
        echo "✅ Server is UP - HTTP $response (Response time: ${response_time}s)"
        if [ ! -z "$pid" ]; then
            echo "   Process PID: $pid"
            # Get memory usage
            ps_output=$(ps aux | grep -E "^[^ ]+ +$pid " | grep -v grep)
            if [ ! -z "$ps_output" ]; then
                mem=$(echo "$ps_output" | awk '{print $4}')
                cpu=$(echo "$ps_output" | awk '{print $3}')
                echo "   CPU: ${cpu}% | Memory: ${mem}%"
            fi
        fi
    else
        echo "❌ Server is DOWN - HTTP $response"
        if [ -z "$pid" ]; then
            echo "   No process found"
        fi
        
        # Check last few lines of log for errors
        echo "   Last log entries:"
        tail -5 server-monitor.log | grep -E "(ERR|FTL|Exception)" | tail -3
    fi
    
    # Sleep for 30 seconds
    sleep 30
done