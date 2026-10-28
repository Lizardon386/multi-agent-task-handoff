@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "GIT="
for /f "delims=" %%i in ('where git 2^>nul') do if not defined GIT set "GIT=%%i"
if not defined GIT (
  echo 没找到 git，请先安装 Git for Windows。
  pause
  exit /b 1
)

for %%i in ("%GIT%") do set "GITBIN=%%~dpi"
set "BASH="
for %%p in ("%GITBIN%bash.exe" "%GITBIN%..\..\bin\bash.exe" "%GITBIN%..\bin\bash.exe" "%GITBIN%..\..\usr\bin\bash.exe") do if not defined BASH if exist "%%~fp" set "BASH=%%~fp"
if not defined BASH (
  echo 没找到 bash，请确认 Git 安装完整。
  pause
  exit /b 1
)

"%BASH%" install.sh %*
set "RC=%ERRORLEVEL%"

if not "%RC%"=="2" goto done

echo.
set /p HOST=没识别出当前宿主，请输入 qoder / claude / codex / opencode:
if "%HOST%"=="" goto abort
"%BASH%" install.sh --host "%HOST%" %*
set "RC=%ERRORLEVEL%"
goto done

:abort
echo 未输入宿主，已取消。
pause
exit /b 2

:done
echo.
pause
exit /b %RC%
