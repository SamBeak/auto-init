# ============================================
# Windows 풀스택 개발 환경 자동 설치 시스템
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

# 스크립트 경로
$ScriptRoot = $PSScriptRoot

# 유틸리티 로드
. "$ScriptRoot\scripts\utils.ps1"

# 배너 출력
Show-Banner

# 관리자 권한 확인
Require-Administrator

# ============================================
# 메뉴 함수
# ============================================

function Show-MainMenu {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    설치 모드 선택" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 빠른 설치 (풀스택 개발자 - 모든 도구)" -ForegroundColor White
    Write-Host "  [2] 프론트엔드 개발자" -ForegroundColor White
    Write-Host "  [3] 백엔드 개발자" -ForegroundColor White
    Write-Host "  [4] 데이터 엔지니어" -ForegroundColor White
    Write-Host "  [5] 사용자 정의 선택" -ForegroundColor White
    Write-Host "  [6] 설치 검증만 실행" -ForegroundColor Yellow
    Write-Host "  [0] 종료" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-UserChoice {
    $choice = Read-Host "선택 (0-6)"
    return $choice
}

# ============================================
# 데이터베이스 설정 입력 함수
# ============================================

function Get-DatabaseConfiguration {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  데이터베이스 설정" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "각 데이터베이스의 설정을 입력하세요." -ForegroundColor Yellow
    Write-Host "(Enter키를 누르면 기본값이 사용됩니다)" -ForegroundColor Yellow
    Write-Host ""

    $dbConfig = @{}

    # PostgreSQL 설정
    Write-Host "=== PostgreSQL 설정 ===" -ForegroundColor Green
    $dbConfig.PostgreSQL = @{
        Port = Read-Host "포트 번호 (기본: 5432)"
        Username = Read-Host "사용자 이름 (기본: postgres)"
        Password = Read-Host "비밀번호 (기본: postgres)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.PostgreSQL.Port)) { $dbConfig.PostgreSQL.Port = "5432" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.PostgreSQL.Username)) { $dbConfig.PostgreSQL.Username = "postgres" }
    $pgPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.PostgreSQL.Password))
    if ([string]::IsNullOrWhiteSpace($pgPassPlain)) { $pgPassPlain = "postgres" }
    $dbConfig.PostgreSQL.Password = $pgPassPlain
    Write-Host ""

    # MySQL 설정
    Write-Host "=== MySQL 설정 ===" -ForegroundColor Green
    $dbConfig.MySQL = @{
        Port = Read-Host "포트 번호 (기본: 3306)"
        Username = Read-Host "Root 사용자 (기본: root)"
        Password = Read-Host "Root 비밀번호 (기본: root)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MySQL.Port)) { $dbConfig.MySQL.Port = "3306" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MySQL.Username)) { $dbConfig.MySQL.Username = "root" }
    $mysqlPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.MySQL.Password))
    if ([string]::IsNullOrWhiteSpace($mysqlPassPlain)) { $mysqlPassPlain = "root" }
    $dbConfig.MySQL.Password = $mysqlPassPlain
    Write-Host ""

    # MongoDB 설정
    Write-Host "=== MongoDB 설정 ===" -ForegroundColor Green
    $dbConfig.MongoDB = @{
        Port = Read-Host "포트 번호 (기본: 27017)"
        Username = Read-Host "관리자 사용자 (기본: admin)"
        Password = Read-Host "관리자 비밀번호 (기본: admin)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MongoDB.Port)) { $dbConfig.MongoDB.Port = "27017" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MongoDB.Username)) { $dbConfig.MongoDB.Username = "admin" }
    $mongoPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.MongoDB.Password))
    if ([string]::IsNullOrWhiteSpace($mongoPassPlain)) { $mongoPassPlain = "admin" }
    $dbConfig.MongoDB.Password = $mongoPassPlain
    Write-Host ""

    # Redis 설정
    Write-Host "=== Redis 설정 ===" -ForegroundColor Green
    $dbConfig.Redis = @{
        Port = Read-Host "포트 번호 (기본: 6379)"
        Password = Read-Host "비밀번호 (선택, Enter로 건너뛰기)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.Redis.Port)) { $dbConfig.Redis.Port = "6379" }
    $redisPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.Redis.Password))
    $dbConfig.Redis.Password = $redisPassPlain
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    return $dbConfig
}

# ============================================
# 설치 프로파일
# ============================================

function Install-FullStack {
    Write-Log "풀스택 개발 환경 설치를 시작합니다..." -Level INFO

    # 패키지 관리자
    & "$ScriptRoot\config\chocolatey.ps1"
    & "$ScriptRoot\config\winget.ps1"

    # 핵심 도구
    & "$ScriptRoot\config\git.ps1"
    & "$ScriptRoot\config\node.ps1"
    & "$ScriptRoot\config\python.ps1"
    & "$ScriptRoot\config\java.ps1"
    & "$ScriptRoot\config\docker.ps1"
    & "$ScriptRoot\config\vscode.ps1"

    # 전자정부프레임워크
    & "$ScriptRoot\config\egovframework.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    & "$ScriptRoot\config\tools.ps1"
    & "$ScriptRoot\config\linters.ps1"

    Write-Log "풀스택 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-Frontend {
    Write-Log "프론트엔드 개발 환경 설치를 시작합니다..." -Level INFO

    # 패키지 관리자
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    & "$ScriptRoot\config\git.ps1"
    & "$ScriptRoot\config\node.ps1"
    & "$ScriptRoot\config\vscode.ps1"

    # 추가 도구
    & "$ScriptRoot\config\tools.ps1"
    & "$ScriptRoot\config\linters.ps1"

    Write-Log "프론트엔드 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-Backend {
    Write-Log "백엔드 개발 환경 설치를 시작합니다..." -Level INFO

    # 패키지 관리자
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    & "$ScriptRoot\config\git.ps1"
    & "$ScriptRoot\config\node.ps1"
    & "$ScriptRoot\config\python.ps1"
    & "$ScriptRoot\config\java.ps1"
    & "$ScriptRoot\config\docker.ps1"
    & "$ScriptRoot\config\vscode.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    & "$ScriptRoot\config\tools.ps1"

    Write-Log "백엔드 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-DataEngineer {
    Write-Log "데이터 엔지니어 환경 설치를 시작합니다..." -Level INFO

    # 패키지 관리자
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    & "$ScriptRoot\config\git.ps1"
    & "$ScriptRoot\config\python.ps1"
    & "$ScriptRoot\config\docker.ps1"
    & "$ScriptRoot\config\vscode.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    . "$ScriptRoot\config\chocolatey.ps1"
    Install-ChocolateyPackage -PackageName "apache-spark"

    Write-Log "데이터 엔지니어 환경 설치 완료!" -Level SUCCESS
}

function Install-Custom {
    Write-Log "사용자 정의 설치를 시작합니다..." -Level INFO

    Write-Host "`n설치할 도구를 선택하세요 (Y/N):`n" -ForegroundColor Cyan

    # 패키지 관리자
    if (Confirm-Action "Chocolatey 패키지 관리자 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\chocolatey.ps1"
    }

    # Git
    if (Confirm-Action "Git 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\git.ps1"
    }

    # Node.js
    if (Confirm-Action "Node.js 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\node.ps1"
    }

    # Python
    if (Confirm-Action "Python 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\python.ps1"
    }

    # Java
    if (Confirm-Action "Java 설치?" -DefaultYes $false) {
        & "$ScriptRoot\config\java.ps1"
    }

    # Docker
    if (Confirm-Action "Docker Desktop 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\docker.ps1"
    }

    # VS Code
    if (Confirm-Action "Visual Studio Code 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\vscode.ps1"
    }

    # 데이터베이스
    if (Confirm-Action "데이터베이스 설치 (PostgreSQL, MySQL, MongoDB, Redis)?" -DefaultYes $true) {
        # 데이터베이스 설정 입력
        $dbConfig = Get-DatabaseConfiguration

        # 데이터베이스 설치
        . "$ScriptRoot\config\database.ps1"
        Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
        Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
        Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
        Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
        Install-SQLiteStudio
        Start-DatabaseServices
        Set-DatabaseAutoStart
    }

    # 추가 도구
    if (Confirm-Action "추가 도구 설치 (Postman, HeidiSQL, Oh My Posh 등)?" -DefaultYes $true) {
        & "$ScriptRoot\config\tools.ps1"
    }

    # 린터
    if (Confirm-Action "코드 품질 도구 설치 (Prettier, ESLint)?" -DefaultYes $true) {
        & "$ScriptRoot\config\linters.ps1"
    }

    # 전자정부프레임워크
    if (Confirm-Action "전자정부프레임워크 3.10 설치?" -DefaultYes $false) {
        & "$ScriptRoot\config\egovframework.ps1"
    }

    Write-Log "사용자 정의 설치 완료!" -Level SUCCESS
}

# ============================================
# 메인 로직
# ============================================

function Start-Installation {
    $startTime = Get-Date

    while ($true) {
        Show-MainMenu
        $choice = Get-UserChoice

        switch ($choice) {
            "1" {
                Write-Log "풀스택 개발자 모드 선택" -Level INFO
                Install-FullStack
                break
            }
            "2" {
                Write-Log "프론트엔드 개발자 모드 선택" -Level INFO
                Install-Frontend
                break
            }
            "3" {
                Write-Log "백엔드 개발자 모드 선택" -Level INFO
                Install-Backend
                break
            }
            "4" {
                Write-Log "데이터 엔지니어 모드 선택" -Level INFO
                Install-DataEngineer
                break
            }
            "5" {
                Write-Log "사용자 정의 모드 선택" -Level INFO
                Install-Custom
                break
            }
            "6" {
                Write-Log "설치 검증 실행" -Level INFO
                & "$ScriptRoot\scripts\validator.ps1"
                continue
            }
            "0" {
                Write-Log "설치를 종료합니다." -Level INFO
                exit 0
            }
            default {
                Write-Log "잘못된 선택입니다. 다시 선택해주세요." -Level WARNING
                continue
            }
        }

        break
    }

    # 설치 후 검증
    Write-Host "`n" -NoNewline
    if (Confirm-Action "설치 검증을 실행하시겠습니까?" -DefaultYes $true) {
        & "$ScriptRoot\scripts\validator.ps1"
    }

    # 완료 메시지
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  설치가 완료되었습니다!" -ForegroundColor Green
    Write-Host "  소요 시간: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    # 재시작 권장
    if (Confirm-Action "시스템을 재시작하시겠습니까?" -DefaultYes $false) {
        Write-Log "시스템을 재시작합니다..." -Level INFO
        Restart-Computer -Force
    } else {
        Write-Log "일부 변경사항을 적용하려면 시스템 재시작이 필요할 수 있습니다." -Level WARNING
    }
}

# 스크립트 실행
try {
    Start-Installation
} catch {
    Write-Log "치명적인 오류가 발생했습니다: $($_.Exception.Message)" -Level ERROR
    Write-Log "스택 트레이스: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}
