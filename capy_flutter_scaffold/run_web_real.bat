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
  echo Usage: run_web_real.bat ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
  echo Example: run_web_real.bat https://api.example.com eyJhbGciOi...
  exit /b 1
)

if "%~2"=="" (
  echo Missing ACCESS_TOKEN
  echo Usage: run_web_real.bat ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
  exit /b 1
)

set "API_BASE_URL=%~1"
set "ACCESS_TOKEN=%~2"

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

echo [4/4] Run web app in REAL API mode...
call "%FLUTTER_CMD%" run -d chrome --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ACCESS_TOKEN=%ACCESS_TOKEN%
if errorlevel 1 (
  echo Failed: flutter run web (real mode)
  exit /b 1
)

endlocal
