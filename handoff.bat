@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
rem 运行时入口：诊断与同步。安装用 安装.bat。

set "GIT="
for /f "delims=" %%i in ('where git 2^>nul') do if not defined GIT set "GIT=%%i"
if not defined GIT (
  echo 没找到 git，请先安装 Git for Windows。
  if "%~1"=="" pause
  exit /b 1
)

for %%i in ("%GIT%") do set "GITBIN=%%~dpi"
set "BASH="
for %%p in ("%GITBIN%bash.exe" "%GITBIN%..\..\bin\bash.exe" "%GITBIN%..\bin\bash.exe" "%GITBIN%..\..\usr\bin\bash.exe") do if not defined BASH if exist "%%~fp" set "BASH=%%~fp"
if not defined BASH (
  echo 没找到 bash，请确认 Git 安装完整。
  if "%~1"=="" pause
  exit /b 1
)

"%BASH%" handoff.sh %*
set "RC=%ERRORLEVEL%"

if "%~1"=="" pause
exit /b %RC%
