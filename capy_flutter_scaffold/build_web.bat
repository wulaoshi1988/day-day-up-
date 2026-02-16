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
    goto :fail
  )
)

set "MODE=%~1"
if "%MODE%"=="" set "MODE=mock"

set "DART_DEFINES="

if /i "%MODE%"=="mock" (
  set "DART_DEFINES=--dart-define=USE_MOCK_API=true"
) else if /i "%MODE%"=="real" (
  if "%~2"=="" (
    echo Usage:
    echo   build_web.bat mock
    echo   build_web.bat real ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
    goto :fail
  )
  if "%~3"=="" (
    echo Missing ACCESS_TOKEN
    echo Usage: build_web.bat real ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
    goto :fail
  )
  set "API_BASE_URL=%~2"
  set "ACCESS_TOKEN=%~3"
  set "DART_DEFINES=--dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=%API_BASE_URL% --dart-define=ACCESS_TOKEN=%ACCESS_TOKEN%"
) else (
  echo Unknown mode: %MODE%
  echo Usage:
  echo   build_web.bat mock
  echo   build_web.bat real ^<API_BASE_URL^> ^<ACCESS_TOKEN^>
  goto :fail
)

echo [1/4] Enable Flutter web...
call "%FLUTTER_CMD%" config --enable-web
if errorlevel 1 (
  echo Failed: flutter config --enable-web
  goto :fail
)

echo [2/4] Generate missing web platform files...
call "%FLUTTER_CMD%" create --platforms=web .
if errorlevel 1 (
  echo Failed: flutter create --platforms=web .
  goto :fail
)

echo [3/4] Get dependencies...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo Failed: flutter pub get
  goto :fail
)

echo [4/4] Build web release package...
call "%FLUTTER_CMD%" build web --release %DART_DEFINES%
if errorlevel 1 (
  echo Failed: flutter build web
  goto :fail
)

echo Build complete: %cd%\build\web
exit /b 0

:fail
echo.
echo Build failed. Press any key to close this window.
pause >nul
exit /b 1

endlocal
