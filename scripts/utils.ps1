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
# 설치 결과 추적
# ============================================

$global:InstallResults = @{
    Success = [System.Collections.ArrayList]@()
    Failed = [System.Collections.ArrayList]@()
    Skipped = [System.Collections.ArrayList]@()
}

function Initialize-InstallResults {
    $global:InstallResults = @{
        Success = [System.Collections.ArrayList]@()
        Failed = [System.Collections.ArrayList]@()
        Skipped = [System.Collections.ArrayList]@()
    }
}

function Add-InstallResult {
    param(
        [string]$ToolName,
        [ValidateSet('Success', 'Failed', 'Skipped')]
        [string]$Status,
        [string]$Message = ""
    )
    
    $result = @{
        Name = $ToolName
        Time = Get-Date -Format "HH:mm:ss"
        Message = $Message
    }
    
    $global:InstallResults[$Status].Add($result) | Out-Null
    
    switch ($Status) {
        'Success' { Write-Log "$ToolName 설치 성공" -Level SUCCESS }
        'Failed'  { Write-Log "$ToolName 설치 실패: $Message" -Level ERROR }
        'Skipped' { Write-Log "$ToolName 건너뜀: $Message" -Level INFO }
    }
}

function Show-InstallSummary {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              설치 결과 요약                           ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # 성공
    $successCount = $global:InstallResults.Success.Count
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "✅ 성공: $successCount개" -ForegroundColor Green -NoNewline
    Write-Host (" " * (43 - "✅ 성공: $successCount개".Length)) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    foreach ($item in $global:InstallResults.Success) {
        $name = $item.Name
        Write-Host "║     " -ForegroundColor Cyan -NoNewline
        Write-Host "• $name" -ForegroundColor White -NoNewline
        Write-Host (" " * (48 - $name.Length)) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
    }
    
    # 실패
    $failedCount = $global:InstallResults.Failed.Count
    if ($failedCount -gt 0) {
        Write-Host "║  " -ForegroundColor Cyan -NoNewline
        Write-Host "❌ 실패: $failedCount개" -ForegroundColor Red -NoNewline
        Write-Host (" " * (43 - "❌ 실패: $failedCount개".Length)) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
        
        foreach ($item in $global:InstallResults.Failed) {
            $name = $item.Name
            Write-Host "║     " -ForegroundColor Cyan -NoNewline
            Write-Host "• $name" -ForegroundColor Red -NoNewline
            Write-Host (" " * (48 - $name.Length)) -NoNewline
            Write-Host "║" -ForegroundColor Cyan
        }
    }
    
    # 건너뜀
    $skippedCount = $global:InstallResults.Skipped.Count
    if ($skippedCount -gt 0) {
        Write-Host "║  " -ForegroundColor Cyan -NoNewline
        Write-Host "⏭️ 건너뜀: $skippedCount개" -ForegroundColor Yellow -NoNewline
        Write-Host (" " * (41 - "⏭️ 건너뜀: $skippedCount개".Length)) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
        
        foreach ($item in $global:InstallResults.Skipped) {
            $name = $item.Name
            Write-Host "║     " -ForegroundColor Cyan -NoNewline
            Write-Host "• $name" -ForegroundColor Yellow -NoNewline
            Write-Host (" " * (48 - $name.Length)) -NoNewline
            Write-Host "║" -ForegroundColor Cyan
        }
    }
    
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 로그 파일에도 기록
    Write-Log "설치 결과 - 성공: $successCount, 실패: $failedCount, 건너뜀: $skippedCount" -Level INFO
}

# ============================================
# 에러 복구 메커니즘
# ============================================

function Invoke-WithRetry {
    param(
        [string]$ToolName,
        [scriptblock]$Action,
        [int]$MaxRetries = 2,
        [switch]$ContinueOnFailure
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $result = & $Action
            
            if ($result -eq $true -or $LASTEXITCODE -eq 0) {
                Add-InstallResult -ToolName $ToolName -Status Success
                return $true
            }
        } catch {
            Write-Log "$ToolName 설치 시도 $attempt/$MaxRetries 실패: $($_.Exception.Message)" -Level WARNING
        }
        
        if ($attempt -lt $MaxRetries) {
            Write-Log "$ToolName 재시도 중... ($attempt/$MaxRetries)" -Level WARNING
            Start-Sleep -Seconds 3
        }
    }
    
    # 모든 재시도 실패
    if ($ContinueOnFailure) {
        $continue = Read-Host "$ToolName 설치에 실패했습니다. 계속 진행하시겠습니까? (Y/N)"
        if ($continue -eq 'Y' -or $continue -eq 'y') {
            Add-InstallResult -ToolName $ToolName -Status Failed -Message "사용자가 계속 진행 선택"
            return $false
        } else {
            Add-InstallResult -ToolName $ToolName -Status Failed -Message "사용자가 중단 선택"
            throw "사용자가 설치를 중단했습니다."
        }
    } else {
        Add-InstallResult -ToolName $ToolName -Status Failed -Message "최대 재시도 횟수 초과"
        return $false
    }
}

# ============================================
# 사전 요구사항 체크
# ============================================

function Test-InternetConnection {
    param(
        [string]$TestUrl = "https://community.chocolatey.org",
        [int]$TimeoutSeconds = 10
    )

    Write-Log "인터넷 연결 확인 중..." -Level INFO

    try {
        # DNS 확인
        $dns = Resolve-DnsName -Name "google.com" -ErrorAction Stop -DnsOnly
        if (-not $dns) {
            Write-Log "DNS 확인 실패" -Level ERROR
            return $false
        }

        # HTTP 연결 테스트
        $request = [System.Net.WebRequest]::Create($TestUrl)
        $request.Timeout = $TimeoutSeconds * 1000
        $request.Method = "HEAD"
        
        $response = $request.GetResponse()
        $response.Close()

        Write-Log "인터넷 연결 확인됨" -Level SUCCESS
        return $true

    } catch {
        Write-Log "인터넷 연결 실패: $($_.Exception.Message)" -Level ERROR
        Write-Log "네트워크 연결을 확인하고 다시 시도해주세요." -Level WARNING
        return $false
    }
}

function Test-DiskSpace {
    param(
        [int]$RequiredGB = 20,
        [string]$DriveLetter = $env:SystemDrive
    )

    Write-Log "디스크 공간 확인 중..." -Level INFO

    try {
        $drive = Get-PSDrive -Name $DriveLetter.TrimEnd(':') -ErrorAction Stop
        $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
        $totalSpaceGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)

        Write-Log "드라이브 $DriveLetter - 전체: ${totalSpaceGB}GB, 여유: ${freeSpaceGB}GB" -Level INFO

        if ($freeSpaceGB -lt $RequiredGB) {
            Write-Log "디스크 공간 부족: ${freeSpaceGB}GB (필요: ${RequiredGB}GB 이상)" -Level ERROR
            Write-Log "불필요한 파일을 삭제하고 다시 시도해주세요." -Level WARNING
            return $false
        }

        Write-Log "디스크 공간 충분: ${freeSpaceGB}GB 사용 가능" -Level SUCCESS
        return $true

    } catch {
        Write-Log "디스크 공간 확인 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Test-WindowsVersion {
    Write-Log "Windows 버전 확인 중..." -Level INFO

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $version = [System.Environment]::OSVersion.Version
        $buildNumber = $os.BuildNumber

        Write-Log "OS: $($os.Caption) (빌드 $buildNumber)" -Level INFO

        # Windows 10 1809 (빌드 17763) 이상 확인
        if ($buildNumber -lt 17763) {
            Write-Log "Windows 10 1809 이상이 필요합니다. (현재: 빌드 $buildNumber)" -Level ERROR
            return $false
        }

        Write-Log "Windows 버전 호환됨" -Level SUCCESS
        return $true

    } catch {
        Write-Log "Windows 버전 확인 실패: $($_.Exception.Message)" -Level WARNING
        return $true  # 확인 실패해도 계속 진행
    }
}

function Test-Prerequisites {
    Write-Log "사전 요구사항 확인을 시작합니다..." -Level INFO
    Write-Host ""

    $allPassed = $true

    # 1. Windows 버전 체크
    if (-not (Test-WindowsVersion)) {
        $allPassed = $false
    }

    # 2. 인터넷 연결 체크
    if (-not (Test-InternetConnection)) {
        $allPassed = $false
    }

    # 3. 디스크 공간 체크
    if (-not (Test-DiskSpace -RequiredGB 15)) {
        $allPassed = $false
    }

    Write-Host ""

    if ($allPassed) {
        Write-Log "모든 사전 요구사항이 충족되었습니다." -Level SUCCESS
    } else {
        Write-Log "일부 사전 요구사항이 충족되지 않았습니다." -Level WARNING
    }

    return $allPassed
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
    param(
        [string]$ScriptPath = $null
    )

    if (-not (Test-Administrator)) {
        Write-Log "관리자 권한이 필요합니다. 관리자로 다시 실행해주세요." -Level ERROR
        Write-Host "`n스크립트를 관리자 권한으로 다시 실행하려면 Enter를 누르세요..." -ForegroundColor Yellow
        Read-Host

        # 관리자 권한으로 재시작 (호출자의 스크립트 경로 사용)
        if ([string]::IsNullOrEmpty($ScriptPath)) {
            $ScriptPath = $PSCommandPath
        }
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
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

# 유틸리티 함수 로드 완료
