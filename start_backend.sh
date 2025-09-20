#!/bin/bash

# JalNetra Backend Server Startup Script
echo "🚀 Starting JalNetra Backend Server..."

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not installed. Please install Dart SDK first."
    echo "📖 Visit: https://dart.dev/get-dart"
    exit 1
fi

# Check if we're in the backend directory
if [ ! -f "backend_server.dart" ]; then
    echo "❌ backend_server.dart not found. Please run this script from the project root."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get

# Start the server
echo "🌐 Starting server on http://localhost:8080"
echo "📊 API Documentation: http://localhost:8080/api/docs"
echo "❤️  Health Check: http://localhost:8080/health"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

dart run backend_server.dart
