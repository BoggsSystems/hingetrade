#!/bin/bash

# Stop all development services for Alpaca Trader API

echo "🛑 Stopping Alpaca Trader API Development Environment"
echo "=================================================="

# Stop dotnet processes
echo "🔴 Stopping .NET processes..."
pkill -f "dotnet run" 2>/dev/null && echo "✅ Stopped API and Mock server" || echo "⚠️  No .NET processes found"

# Stop Docker containers
echo "🐳 Stopping Docker containers..."
docker-compose down 2>/dev/null && echo "✅ Docker services stopped" || echo "⚠️  Docker services not running"

# Clean up any orphaned processes
echo "🧹 Cleaning up..."
pkill -f "MockAlpacaServer" 2>/dev/null || true
pkill -f "TraderApi" 2>/dev/null || true

echo ""
echo "✅ All services stopped"
echo "=================================================="