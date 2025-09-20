@echo off
REM JalNetra Backend Server Startup Script for Windows

echo 🚀 Starting JalNetra Backend Server...

REM Check if Dart is installed
where dart >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Dart is not installed. Please install Dart SDK first.
    echo 📖 Visit: https://dart.dev/get-dart
    pause
    exit /b 1
)

REM Check if we're in the correct directory
if not exist "backend_server.dart" (
    echo ❌ backend_server.dart not found. Please run this script from the project root.
    pause
    exit /b 1
)

REM Install dependencies
echo 📦 Installing dependencies...
dart pub get

REM Start the server
echo 🌐 Starting server on http://localhost:8080
echo 📊 API Documentation: http://localhost:8080/api/docs
echo ❤️  Health Check: http://localhost:8080/health
echo.
echo Press Ctrl+C to stop the server
echo.

dart run backend_server.dart

pause
