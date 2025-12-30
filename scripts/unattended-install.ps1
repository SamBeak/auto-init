# ============================================
# 무인 설치 스크립트 (설정 파일 기반)
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

param(
    [string]$ConfigPath = "",
    [switch]$Silent,
    [switch]$Force
)

. "$PSScriptRoot\utils.ps1"

$ScriptRoot = Split-Path -Parent $PSScriptRoot

# ============================================
# 설정 파일 로드
# ============================================

function Get-InstallConfig {
    param([string]$Path)
    
    if ([string]::IsNullOrEmpty($Path)) {
        $Path = Join-Path $ScriptRoot "config.json"
    }
    
    if (-not (Test-Path $Path)) {
        Write-Log "설정 파일을 찾을 수 없습니다: $Path" -Level ERROR
        Write-Log "기본 설정 파일을 생성하려면 다음 명령을 실행하세요:" -Level INFO
        Write-Log "  .\setup.ps1 --generate-config" -Level INFO
        return $null
    }
    
    try {
        $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
        Write-Log "설정 파일 로드 완료: $Path" -Level SUCCESS
        return $config
    } catch {
        Write-Log "설정 파일 파싱 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

# ============================================
# 무인 설치 실행
# ============================================

function Start-UnattendedInstall {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              무인 설치 모드                                   ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 설정 요약 표시
    Write-Log "설정 요약:" -Level INFO
    Write-Log "  프로필: $($Config.profile)" -Level INFO
    Write-Log "  모드: $($Config.mode)" -Level INFO
    Write-Host ""
    
    # 사전 요구사항 확인
    if (-not $Config.options.skipPrerequisiteCheck) {
        $prereqOk = Test-Prerequisites
        if (-not $prereqOk -and -not $Force) {
            Write-Log "사전 요구사항이 충족되지 않았습니다. -Force 옵션으로 강제 실행 가능합니다." -Level ERROR
            return $false
        }
    }
    
    # 설치 결과 초기화
    Initialize-InstallResults
    
    # 패키지 관리자 설치
    if ($Config.tools.packageManagers.chocolatey) {
        Write-Log "Chocolatey 설치 중..." -Level INFO
        & "$ScriptRoot\config\chocolatey.ps1"
    }
    
    if ($Config.tools.packageManagers.winget) {
        Write-Log "Winget 설정 중..." -Level INFO
        & "$ScriptRoot\config\winget.ps1"
    }
    
    # Git 설치
    if ($Config.tools.git.enabled) {
        Write-Log "Git 설치 중..." -Level INFO
        & "$ScriptRoot\config\git.ps1"
    }
    
    # Node.js 설치
    if ($Config.tools.node.enabled) {
        Write-Log "Node.js $($Config.tools.node.version) 설치 중..." -Level INFO
        . "$ScriptRoot\config\node.ps1"
        Install-NVM
        Install-NodeJS -Version $Config.tools.node.version
        
        if ($Config.tools.node.packageManagers -contains "yarn") {
            Install-Yarn
        }
        if ($Config.tools.node.packageManagers -contains "pnpm") {
            Install-Pnpm
        }
    }
    
    # Python 설치
    if ($Config.tools.python.enabled) {
        Write-Log "Python 설치 중..." -Level INFO
        & "$ScriptRoot\config\python.ps1"
    }
    
    # Java 설치
    if ($Config.tools.java.enabled) {
        Write-Log "Java 설치 중..." -Level INFO
        & "$ScriptRoot\config\java.ps1"
    }
    
    # Docker 설치
    if ($Config.tools.docker.enabled) {
        Write-Log "Docker 설치 중..." -Level INFO
        & "$ScriptRoot\config\docker.ps1"
    }
    
    # VS Code 설치
    if ($Config.tools.vscode.enabled) {
        Write-Log "VS Code 설치 중..." -Level INFO
        & "$ScriptRoot\config\vscode.ps1"
    }
    
    # 전자정부프레임워크
    if ($Config.tools.egovframework.enabled) {
        Write-Log "전자정부프레임워크 설치 중..." -Level INFO
        & "$ScriptRoot\config\egovframework.ps1"
    }
    
    # 데이터베이스 설치
    . "$ScriptRoot\config\database.ps1"
    
    if ($Config.databases.postgresql.enabled) {
        Write-Log "PostgreSQL 설치 중..." -Level INFO
        Install-PostgreSQL -Port $Config.databases.postgresql.port `
                          -Username $Config.databases.postgresql.username `
                          -Password $Config.databases.postgresql.password
    }
    
    if ($Config.databases.mysql.enabled) {
        Write-Log "MySQL 설치 중..." -Level INFO
        Install-MySQL -Port $Config.databases.mysql.port `
                     -Username $Config.databases.mysql.username `
                     -Password $Config.databases.mysql.password
    }
    
    if ($Config.databases.mongodb.enabled) {
        Write-Log "MongoDB 설치 중..." -Level INFO
        Install-MongoDB -Port $Config.databases.mongodb.port `
                       -Username $Config.databases.mongodb.username `
                       -Password $Config.databases.mongodb.password
    }
    
    if ($Config.databases.redis.enabled) {
        Write-Log "Redis 설치 중..." -Level INFO
        Install-Redis -Port $Config.databases.redis.port `
                     -Password $Config.databases.redis.password
    }
    
    # 추가 도구 설치
    . "$ScriptRoot\config\tools.ps1"
    
    if ($Config.additionalTools.powershell7) {
        Install-PowerShell7
    }
    if ($Config.additionalTools.windowsTerminal) {
        Install-WindowsTerminal
    }
    if ($Config.additionalTools.ohMyPosh) {
        Install-OhMyPosh
    }
    if ($Config.additionalTools.postman) {
        Install-Postman
    }
    
    # 린터 설치
    if ($Config.linters.prettier -or $Config.linters.eslint) {
        Write-Log "코드 품질 도구 설치 중..." -Level INFO
        & "$ScriptRoot\config\linters.ps1"
    }
    
    # 설치 결과 요약
    Show-InstallSummary
    
    # 자동 재시작
    if ($Config.options.autoRestart) {
        Write-Log "시스템을 재시작합니다..." -Level INFO
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    }
    
    return $true
}

# ============================================
# 메인 실행
# ============================================

if ($MyInvocation.InvocationName -ne '.') {
    Write-Log "무인 설치 모드를 시작합니다..." -Level INFO
    
    $config = Get-InstallConfig -Path $ConfigPath
    
    if ($null -eq $config) {
        Write-Log "설정 파일을 로드할 수 없습니다." -Level ERROR
        exit 1
    }
    
    $result = Start-UnattendedInstall -Config $config
    
    if ($result) {
        Write-Log "무인 설치가 완료되었습니다." -Level SUCCESS
        exit 0
    } else {
        Write-Log "무인 설치 중 오류가 발생했습니다." -Level ERROR
        exit 1
    }
}
