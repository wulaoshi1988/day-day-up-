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

echo [1/4] Enable Flutter web...
call "%FLUTTER_CMD%" config --enable-web
if errorlevel 1 (
  echo Failed: flutter config --enable-web
  exit /b 1
)

echo [2/4] Generate missing web platform files...
call "%FLUTTER_CMD%" create --platforms=web .
if errorlevel 1 (
  echo Failed: flutter create --platforms=web .
  exit /b 1
)

echo [3/4] Get dependencies...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo Failed: flutter pub get
  exit /b 1
)

echo [4/4] Run web app in MOCK mode...
call "%FLUTTER_CMD%" run -d chrome --dart-define=USE_MOCK_API=true
if errorlevel 1 (
  echo Failed: flutter run web (mock mode)
  exit /b 1
)

endlocal
