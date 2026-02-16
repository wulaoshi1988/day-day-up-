@echo off
setlocal

cd /d "%~dp0"

set "FLUTTER_CMD=flutter"
where flutter >nul 2>nul
if errorlevel 1 (
  if exist "C:\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
  ) else (
    echo Flutter not found in PATH and C:\flutter\bin\flutter.bat not found.
    echo Please install Flutter or add it to PATH.
    pause
    exit /b 1
  )
)

if "%~1"=="" (
  echo Usage: run_real.bat ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
  echo Example: run_real.bat https://api.example.com eyJhbGciOi...
  exit /b 1
)

if "%~2"=="" (
  echo Missing ACCESS_TOKEN
  echo Usage: run_real.bat ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
  exit /b 1
)

set "API_BASE_URL=%~1"
set "ACCESS_TOKEN=%~2"

echo [1/2] Getting Flutter dependencies...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo Failed: flutter pub get
  exit /b 1
)

echo [2/2] Running app in REAL API mode...
call "%FLUTTER_CMD%" run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ACCESS_TOKEN=%ACCESS_TOKEN%
if errorlevel 1 (
  echo Failed: flutter run (real mode)
  exit /b 1
)

endlocal
