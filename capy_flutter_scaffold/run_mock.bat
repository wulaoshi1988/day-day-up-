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

echo [1/2] Getting Flutter dependencies...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo Failed: flutter pub get
  exit /b 1
)

echo [2/2] Running app in MOCK mode...
call "%FLUTTER_CMD%" run --dart-define=USE_MOCK_API=true
if errorlevel 1 (
  echo Failed: flutter run (mock mode)
  exit /b 1
)

endlocal
