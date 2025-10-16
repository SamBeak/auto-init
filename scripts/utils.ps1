# ============================================
# Windows 개발 환경 자동 설치 - 유틸리티 함수
# ============================================

# 로그 디렉토리 설정
$global:LogDir = Join-Path $PSScriptRoot "..\logs"
$global:InstallLog = Join-Path $LogDir "install.log"
$global:ErrorLog = Join-Path $LogDir "error.log"

# 로그 디렉토리 생성
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# ============================================
# 로깅 함수
# ============================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # 콘솔 출력 (색상 포함)
    switch ($Level) {
        'INFO'    { Write-Host $logMessage -ForegroundColor Cyan }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
    }

    # 파일 로그
    Add-Content -Path $InstallLog -Value $logMessage

    if ($Level -eq 'ERROR') {
        Add-Content -Path $ErrorLog -Value $logMessage
    }
}

# ============================================
# 권한 확인
# ============================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Require-Administrator {
    if (-not (Test-Administrator)) {
        Write-Log "관리자 권한이 필요합니다. 관리자로 다시 실행해주세요." -Level ERROR
        Write-Host "`n스크립트를 관리자 권한으로 다시 실행하려면 Enter를 누르세요..." -ForegroundColor Yellow
        Read-Host

        # 관리자 권한으로 재시작
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# ============================================
# 프로그램 설치 확인
# ============================================

function Test-ProgramInstalled {
    param(
        [string]$ProgramName,
        [string]$CommandCheck = $null
    )

    # 명령어로 확인
    if ($CommandCheck) {
        try {
            $null = & $CommandCheck --version 2>&1
            return $true
        } catch {
            return $false
        }
    }

    # 레지스트리에서 확인
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $programs = Get-ItemProperty $path -ErrorAction SilentlyContinue
        if ($programs | Where-Object { $_.DisplayName -like "*$ProgramName*" }) {
            return $true
        }
    }

    return $false
}

# ============================================
# 진행 상황 표시
# ============================================

function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

# ============================================
# 사용자 확인 프롬프트
# ============================================

function Confirm-Action {
    param(
        [string]$Message,
        [bool]$DefaultYes = $true
    )

    $choices = '&Yes', '&No'
    $default = if ($DefaultYes) { 0 } else { 1 }

    $result = $Host.UI.PromptForChoice('확인', $Message, $choices, $default)
    return ($result -eq 0)
}

# ============================================
# 환경 변수 추가
# ============================================

function Add-PathVariable {
    param(
        [string]$Path,
        [ValidateSet('User', 'Machine')]
        [string]$Scope = 'User'
    )

    if (-not (Test-Path $Path)) {
        Write-Log "경로가 존재하지 않습니다: $Path" -Level WARNING
        return
    }

    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)

    if ($currentPath -notlike "*$Path*") {
        $newPath = "$currentPath;$Path"
        [Environment]::SetEnvironmentVariable('Path', $newPath, $Scope)
        Write-Log "PATH에 추가됨: $Path" -Level SUCCESS

        # 현재 세션에도 적용
        $env:Path += ";$Path"
    } else {
        Write-Log "PATH에 이미 존재함: $Path" -Level INFO
    }
}

# ============================================
# 다운로드 함수
# ============================================

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    try {
        Write-Log "다운로드 중: $Url" -Level INFO

        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)

        Write-Log "다운로드 완료: $OutputPath" -Level SUCCESS
        return $true
    } catch {
        Write-Log "다운로드 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================
# 설치 대기 함수
# ============================================

function Wait-ProcessComplete {
    param(
        [string]$ProcessName,
        [int]$TimeoutSeconds = 300
    )

    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)

    while (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        if ((Get-Date) -gt $timeout) {
            Write-Log "프로세스 대기 시간 초과: $ProcessName" -Level WARNING
            return $false
        }
        Start-Sleep -Seconds 2
    }

    return $true
}

# ============================================
# 버전 비교
# ============================================

function Compare-Version {
    param(
        [string]$CurrentVersion,
        [string]$RequiredVersion
    )

    try {
        $current = [version]$CurrentVersion
        $required = [version]$RequiredVersion

        return ($current -ge $required)
    } catch {
        Write-Log "버전 비교 실패: $($_.Exception.Message)" -Level WARNING
        return $false
    }
}

# ============================================
# 백업 함수
# ============================================

function Backup-Configuration {
    param(
        [string]$ConfigPath,
        [string]$BackupDir = (Join-Path $PSScriptRoot "..\data\backup")
    )

    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    if (Test-Path $ConfigPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path $ConfigPath -Leaf
        $backupPath = Join-Path $BackupDir "${fileName}.${timestamp}.bak"

        Copy-Item -Path $ConfigPath -Destination $backupPath -Force
        Write-Log "백업 완료: $backupPath" -Level SUCCESS
        return $backupPath
    }

    return $null
}

# ============================================
# JSON 설정 로드
# ============================================

function Get-ConfigurationData {
    param(
        [string]$ConfigFile = "config.json"
    )

    $configPath = Join-Path $PSScriptRoot "..\$ConfigFile"

    if (Test-Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "설정 파일 로드 실패: $($_.Exception.Message)" -Level ERROR
            return $null
        }
    } else {
        Write-Log "설정 파일을 찾을 수 없습니다: $configPath" -Level WARNING
        return $null
    }
}

# ============================================
# 설치 성공 확인
# ============================================

function Test-InstallationSuccess {
    param(
        [string]$Command,
        [string]$ExpectedOutput = $null
    )

    try {
        $output = & $Command --version 2>&1 | Out-String

        if ($ExpectedOutput) {
            return ($output -like "*$ExpectedOutput*")
        }

        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# ============================================
# 배너 출력
# ============================================

function Show-Banner {
    $banner = @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Windows 풀스택 개발 환경 자동 설치 시스템              ║
║   Fullstack Development Environment Auto Setup           ║
║                                                           ║
║   Version: 1.0.0                                          ║
║   Author: Auto-Init Team                                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

# ============================================
# 완료 메시지
# ============================================

function Show-CompletionMessage {
    param(
        [int]$SuccessCount,
        [int]$FailCount,
        [int]$TotalCount
    )

    $message = @"

╔═══════════════════════════════════════════════════════════╗
║                    설치 완료!                             ║
╚═══════════════════════════════════════════════════════════╝

총 $TotalCount 개 항목 중:
  ✓ 성공: $SuccessCount
  ✗ 실패: $FailCount

로그 파일: $InstallLog
에러 로그: $ErrorLog

시스템 재시작을 권장합니다.

"@

    if ($FailCount -eq 0) {
        Write-Host $message -ForegroundColor Green
    } else {
        Write-Host $message -ForegroundColor Yellow
    }
}

# ============================================
# 에러 핸들링
# ============================================

function Invoke-SafeExecution {
    param(
        [scriptblock]$ScriptBlock,
        [string]$ErrorMessage = "작업 실행 중 오류 발생"
    )

    try {
        & $ScriptBlock
        return $true
    } catch {
        Write-Log "$ErrorMessage : $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 모듈 내보내기
Export-ModuleMember -Function *
