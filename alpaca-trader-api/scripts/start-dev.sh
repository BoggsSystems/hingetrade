#!/bin/bash

# Development startup script for Alpaca Trader API
# This script starts all required services for local development

set -e

echo "🚀 Starting Alpaca Trader API Development Environment"
echo "=================================================="

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ Error: $1 is not installed"
        echo "   Please install $1 before running this script"
        exit 1
    fi
}

echo "📋 Checking prerequisites..."
check_command docker
check_command dotnet
echo "✅ All prerequisites installed"

# Start Docker services
echo ""
echo "🐳 Starting Docker services..."
docker-compose up -d postgres redis mailhog

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if services are running
echo "🔍 Checking service status..."
docker ps | grep postgres > /dev/null && echo "✅ PostgreSQL is running" || echo "❌ PostgreSQL failed to start"
docker ps | grep redis > /dev/null && echo "✅ Redis is running" || echo "❌ Redis failed to start"
docker ps | grep mailhog > /dev/null && echo "✅ MailHog is running" || echo "❌ MailHog failed to start"

# Start mock Alpaca server
echo ""
echo "🎭 Starting mock Alpaca server..."
cd tests/MockAlpacaServer
dotnet run &
MOCK_PID=$!
cd ../..
echo "✅ Mock server started (PID: $MOCK_PID)"

# Wait a moment for mock server to start
sleep 3

# Run database migrations
echo ""
echo "🗄️  Running database migrations..."
cd src/TraderApi
dotnet ef database update || echo "⚠️  Database migration failed (might already be up to date)"

# Start the API
echo ""
echo "🚀 Starting Trader API..."
echo "=================================================="
echo ""
echo "📍 Services running at:"
echo "   - API: http://localhost:5000"
echo "   - Swagger UI: http://localhost:5000/swagger (if in Development mode)"
echo "   - MailHog UI: http://localhost:8025"
echo "   - Mock Alpaca: http://localhost:5001"
echo ""
echo "📝 Demo Authentication:"
echo "   Use header: X-Demo-User-Id: test-user"
echo ""
echo "🛑 Press Ctrl+C to stop all services"
echo "=================================================="
echo ""

# Start the API (this will block)
ASPNETCORE_ENVIRONMENT=Development dotnet run

# Cleanup on exit
echo ""
echo "🧹 Cleaning up..."
kill $MOCK_PID 2>/dev/null || true
docker-compose down
echo "✅ All services stopped"