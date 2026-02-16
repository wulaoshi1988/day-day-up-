@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "SOURCE_IMAGE=%PROJECT_DIR%assets\icons\nav\nav_source.png"

if "%~1"=="" (
  set "INPUT_IMAGE=%SOURCE_IMAGE%"
) else (
  set "INPUT_IMAGE=%~1"
)

if not exist "%INPUT_IMAGE%" (
  echo [ERROR] Source image not found:
  echo         "%INPUT_IMAGE%"
  echo.
  echo Put your image here:
  echo   "%SOURCE_IMAGE%"
  echo or pass image path as argument:
  echo   slice_nav_icons.bat "C:\path\to\your\image.png"
  pause
  exit /b 1
)

where python >nul 2>nul
if %errorlevel%==0 (
  set "PYTHON_CMD=python"
) else (
  if exist "C:\Python313\python.exe" (
    set "PYTHON_CMD=C:\Python313\python.exe"
  ) else (
    echo [ERROR] Python not found. Install Python or add to PATH.
    pause
    exit /b 1
  )
)

echo Using Python: %PYTHON_CMD%
echo Source image: "%INPUT_IMAGE%"
echo.

"%PYTHON_CMD%" "%PROJECT_DIR%tool\slice_nav_icons.py" "%INPUT_IMAGE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Icon slicing failed.
  pause
  exit /b 1
)

echo.
echo [DONE] Nav icons generated under assets\icons\nav\
pause
exit /b 0
