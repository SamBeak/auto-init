@echo off
:: ============================================
:: Windows 개발 환경 자동 설치 - 배치 래퍼
:: ============================================

echo.
echo ========================================
echo   Windows 풀스택 개발 환경 자동 설치
echo ========================================
echo.

:: 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [오류] 이 스크립트는 관리자 권한이 필요합니다.
    echo.
    echo 마우스 우클릭 후 "관리자 권한으로 실행"을 선택하세요.
    echo.
    pause
    exit /b 1
)

:: PowerShell 실행
echo PowerShell 스크립트를 실행합니다...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

pause
