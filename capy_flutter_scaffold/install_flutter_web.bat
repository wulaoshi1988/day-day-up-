@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ==========================================
echo   Flutter Web Setup (Windows)
echo ==========================================
echo.

set "HAS_WINGET=1"
where winget >nul 2>nul
if errorlevel 1 set "HAS_WINGET=0"

if "%HAS_WINGET%"=="0" (
  echo [WARN] winget not found. Auto-install will be skipped.
  echo        You can still continue if Flutter is already installed.
)

where flutter >nul 2>nul
if errorlevel 1 (
  if exist "C:\flutter\bin\flutter.bat" (
    set "PATH=C:\flutter\bin;%PATH%"
    echo [1/6] Found Flutter at C:\flutter\bin\flutter.bat (session PATH updated)
  ) else if exist "C:\src\flutter\bin\flutter.bat" (
    set "PATH=C:\src\flutter\bin;%PATH%"
    echo [1/6] Found Flutter at C:\src\flutter\bin\flutter.bat (session PATH updated)
  ) else if "%HAS_WINGET%"=="1" (
    echo [1/6] Installing Flutter via winget...
    winget install -e --id Google.Flutter --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
      echo Failed to install Flutter with winget.
      goto :fail
    )
  ) else (
    echo [ERROR] Flutter not found and winget is unavailable.
    echo Manual install steps:
    echo   1) Download Flutter SDK zip from: https://docs.flutter.dev/get-started/install/windows
    echo   2) Extract to: C:\flutter (recommended) or C:\src\flutter
    echo   3) Re-run this script (it will auto-detect flutter.bat)
    goto :fail
  )
) else (
  echo [1/6] Flutter already installed.
)

where chrome >nul 2>nul
if errorlevel 1 (
  where msedge >nul 2>nul
  if errorlevel 1 (
    if "%HAS_WINGET%"=="1" (
      echo [2/6] Installing Google Chrome via winget...
      winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements
      if errorlevel 1 (
        echo Failed to install Google Chrome with winget.
        goto :fail
      )
    ) else (
      echo [2/6] No Chrome/Edge detected and winget unavailable.
      echo      Install Chrome manually for web debugging target.
    )
  ) else (
    echo [2/6] Microsoft Edge detected, Chrome install skipped.
  )
) else (
  echo [2/6] Google Chrome already installed.
)

set "FLUTTER_BIN="
for /f "delims=" %%P in ('where flutter 2^>nul') do (
  set "FLUTTER_BIN=%%P"
  goto :have_flutter
)

:have_flutter
if "%FLUTTER_BIN%"=="" (
  echo [ERROR] Flutter still not available in current PATH.
  echo Close this window, open a new terminal, and run this script again.
  goto :fail
)

echo [3/6] Flutter path: %FLUTTER_BIN%
echo [4/6] Enabling web support...
call flutter config --enable-web
if errorlevel 1 (
  echo Failed: flutter config --enable-web
  goto :fail
)

echo [5/6] Installing project dependencies...
call flutter pub get
if errorlevel 1 (
  echo Failed: flutter pub get
  goto :fail
)

echo [6/6] Running flutter doctor...
call flutter doctor
if errorlevel 1 (
  echo flutter doctor reported issues. Please review output above.
)

echo.
echo Setup finished.
echo Next steps:
echo   - Web mock run: run_web_mock.bat
echo   - Web release build: build_web.bat mock
echo.
pause
exit /b 0

:fail
echo.
echo Setup failed. Press any key to close this window.
pause >nul
exit /b 1
