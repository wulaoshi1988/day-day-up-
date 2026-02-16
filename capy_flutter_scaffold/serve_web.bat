@echo off
setlocal

cd /d "%~dp0"

if not exist "build\web\index.html" (
  echo Missing build output: build\web\index.html
  echo Please run: build_web.bat mock
  exit /b 1
)

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8080"

echo Serving build\web at http://localhost:%PORT%/

where py >nul 2>nul
if %errorlevel%==0 (
  py -m http.server %PORT% --directory build\web
  exit /b %errorlevel%
)

where python >nul 2>nul
if %errorlevel%==0 (
  python -m http.server %PORT% --directory build\web
  exit /b %errorlevel%
)

echo Python runtime not found. Install Python or run with another static server.
exit /b 1

endlocal
