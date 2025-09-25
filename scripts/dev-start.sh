#!/bin/bash

# 🚀 Unified Development Startup Script
# Заменяет все manual команды единым процессом запуска

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
ENVIRONMENT=${ENVIRONMENT:-"development"}
DEVICE_TYPE=${1:-"ios-simulator"}  # ios-simulator, android, chrome
SKIP_HEALTH_CHECK=${SKIP_HEALTH_CHECK:-false}

echo "🚀 AIc Development Startup"
echo "📁 Project: $PROJECT_ROOT"
echo "🌍 Environment: $ENVIRONMENT"
echo "📱 Target: $DEVICE_TYPE"
echo ""

# Load environment variables
if [ -f "$PROJECT_ROOT/.env.$ENVIRONMENT" ]; then
    echo "📝 Loading environment: .env.$ENVIRONMENT"
    set -a
    source "$PROJECT_ROOT/.env.$ENVIRONMENT"
    set +a
else
    echo "⚠️  Environment file not found: .env.$ENVIRONMENT"
    echo "   Using default values..."
fi

cd "$PROJECT_ROOT"

# Step 1: Clean previous processes
echo "🧹 Cleaning previous processes..."
"$SCRIPT_DIR/clean-processes.sh"

# Step 2: Health check (if not skipped)
if [ "$SKIP_HEALTH_CHECK" != "true" ]; then
    echo "🏥 Running health check..."
    if ! "$SCRIPT_DIR/health-check.sh"; then
        echo "💥 Health check failed. Starting API server..."

        echo "🔨 Building API..."
        cd "$PROJECT_ROOT/apps/api"
        npm run build

        echo "🚀 Starting API server..."
        HOST=${HOST:-"0.0.0.0"} PORT=${PORT:-"3001"} node dist/main.js &
        API_PID=$!
        echo "   API Server PID: $API_PID"

        # Wait a bit for server to start
        echo "   Waiting for API server to start..."
        sleep 5

        # Run health check again
        cd "$PROJECT_ROOT"
        if ! "$SCRIPT_DIR/health-check.sh"; then
            echo "💥 API server failed to start properly"
            exit 1
        fi
    fi
else
    echo "⏭️  Skipping health check..."
fi

# Step 3: Start Flutter app based on device type
echo "📱 Starting Flutter app..."
cd "$PROJECT_ROOT/apps/mobile"

case "$DEVICE_TYPE" in
    ios-simulator)
        DEVICE_ID=${FLUTTER_DEVICE_ID:-"AC592D75-12E9-40A3-BCCD-E71A95A3F37A"}
        echo "   Target: iOS Simulator ($DEVICE_ID)"
        flutter run -d "$DEVICE_ID" &
        ;;
    ios-device)
        DEVICE_ID=${FLUTTER_DEVICE_ID:-"00008130-00115021348A001C"}
        echo "   Target: iOS Device ($DEVICE_ID)"
        flutter run -d "$DEVICE_ID" &
        ;;
    android)
        echo "   Target: Android"
        flutter run -d android &
        ;;
    chrome)
        echo "   Target: Chrome (Web)"
        flutter run -d chrome &
        ;;
    *)
        echo "❌ Unknown device type: $DEVICE_TYPE"
        echo "   Supported: ios-simulator, ios-device, android, chrome"
        exit 1
        ;;
esac

FLUTTER_PID=$!
echo "   Flutter PID: $FLUTTER_PID"

# Step 4: Show success message and useful info
echo ""
echo "🎉 Development environment started successfully!"
echo ""
echo "📋 Running Services:"
echo "   🚀 API Server: http://${API_HOST:-192.168.68.65}:${API_PORT:-3001}"
echo "   📚 Swagger UI: http://${API_HOST:-192.168.68.65}:${API_PORT:-3001}/api"
echo "   📱 Flutter App: $DEVICE_TYPE"
echo ""
echo "🔧 Useful Commands:"
echo "   Stop all: $SCRIPT_DIR/clean-processes.sh"
echo "   Health check: $SCRIPT_DIR/health-check.sh"
echo "   Logs: Check terminal output above"
echo ""
echo "✨ Happy coding!"

# Wait for user interrupt
wait