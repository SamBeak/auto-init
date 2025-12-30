@echo off
chcp 65001 >nul 2>&1
:: ============================================
:: Windows 개발 환경 자동 설치 - 배치 래퍼
:: ============================================

:: 관리자 권한 자동 상승
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 관리자 권한을 요청합니다...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

echo.
echo ========================================
echo   Windows 풀스택 개발 환경 자동 설치
echo ========================================
echo.

:: PowerShell 실행
echo PowerShell 스크립트를 실행합니다...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8; & '%~dp0setup.ps1'"

if %errorlevel% neq 0 (
    echo.
    echo [오류] 스크립트 실행 중 문제가 발생했습니다.
    echo.
)

pause
