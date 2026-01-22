@echo off
setlocal enabledelayedexpansion

echo ========================================
echo NX Witness QA Lab - Stage 0
echo ========================================
echo.

REM Check if Docker is installed
echo [1/4] Checking Docker installation...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop for Windows
    exit /b 1
)
docker --version
echo.

REM Check if Docker is running
echo [2/4] Checking if Docker is running...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running
    echo Please start Docker Desktop
    exit /b 1
)
echo Docker is running
echo.

REM Check if docker compose is available
echo [3/4] Checking docker compose...
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: docker compose is not available
    echo Please ensure Docker Desktop with WSL2 backend is installed
    exit /b 1
)
docker compose version
echo.

REM Check if NX Witness binary exists
echo [4/5] Checking NX Witness binary...
set "NX_BINARY_DIR=nx-binary"
set "NX_BINARY_FILE=nxwitness-server-6.2.0.42223-linux_x64-private-prod.deb"

if not exist "%NX_BINARY_DIR%\%NX_BINARY_FILE%" (
    echo ERROR: NX Witness binary not found
    echo Expected location: %NX_BINARY_DIR%\%NX_BINARY_FILE%
    echo Please place the NX Witness Server .deb file in the nx-binary directory
    exit /b 1
)
echo Found NX Witness binary: %NX_BINARY_FILE%
echo.

REM Check if MediaMTX config exists
echo [5/5] Checking MediaMTX configuration...
set "CAMERA_CONFIG=docker\camera\mediamtx.yml"

if not exist "%CAMERA_CONFIG%" (
    echo ERROR: MediaMTX configuration not found
    echo Expected location: %CAMERA_CONFIG%
    exit /b 1
)
echo Found MediaMTX configuration: %CAMERA_CONFIG%
echo.

REM Start Docker Compose
echo ========================================
echo Starting NX Witness QA Lab...
echo ========================================
echo.

docker compose up -d --build
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo ERROR: Failed to start containers
    echo ========================================
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS: NX Witness QA Lab is running!
echo ========================================
echo.
echo NX Witness Server: http://localhost:7001
echo RTSP Camera: rtsp://localhost:8554/camera
echo.
echo To stop the lab, run: docker compose down
echo To view logs, run: docker compose logs -f
echo.

exit /b 0
