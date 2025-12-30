# ============================================
# 오프라인 설치 스크립트
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

. "$PSScriptRoot\utils.ps1"

# 캐시 디렉토리
$global:CacheDir = Join-Path $PSScriptRoot "..\cache"
$global:InstallersDir = Join-Path $CacheDir "installers"

# ============================================
# 오프라인 모드 확인
# ============================================

function Test-OfflineMode {
    # 캐시 디렉토리 존재 확인
    if (-not (Test-Path $InstallersDir)) {
        Write-Log "캐시 디렉토리를 찾을 수 없습니다: $InstallersDir" -Level ERROR
        Write-Log "먼저 cache-manager.ps1을 실행하여 패키지를 다운로드하세요." -Level WARNING
        return $false
    }
    
    # 최소 필수 파일 확인
    $requiredFiles = @("chocolatey-install.ps1", "Git-2.43.0-64-bit.exe")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path (Join-Path $InstallersDir $file))) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Log "필수 파일 누락: $($missingFiles -join ', ')" -Level WARNING
        return $false
    }
    
    return $true
}

# ============================================
# 오프라인 설치 함수들
# ============================================

function Install-ChocolateyOffline {
    Write-Log "Chocolatey 오프라인 설치 중..." -Level INFO
    
    $scriptPath = Join-Path $InstallersDir "chocolatey-install.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Log "Chocolatey 설치 스크립트를 찾을 수 없습니다." -Level ERROR
        return $false
    }
    
    try {
        # 환경 변수 설정 (오프라인 모드)
        $env:chocolateyUseWindowsCompression = 'true'
        
        # 스크립트 실행
        & $scriptPath
        
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log "Chocolatey 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "Chocolatey" -Status Success
            return $true
        }
    } catch {
        Write-Log "Chocolatey 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "Chocolatey" -Status Failed
    return $false
}

function Install-GitOffline {
    Write-Log "Git 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "Git-2.43.0-64-bit.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "Git 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "Git" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Log "Git 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "Git" -Status Success
            return $true
        }
    } catch {
        Write-Log "Git 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "Git" -Status Failed
    return $false
}

function Install-NodeJSOffline {
    Write-Log "Node.js 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "node-v22.12.0-x64.msi"
    
    if (-not (Test-Path $installerPath)) {
        # nvm 방식 시도
        $nvmPath = Join-Path $InstallersDir "nvm-setup.exe"
        if (Test-Path $nvmPath) {
            return Install-NvmOffline
        }
        
        Write-Log "Node.js 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "Node.js" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Log "Node.js 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "Node.js" -Status Success
            return $true
        }
    } catch {
        Write-Log "Node.js 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "Node.js" -Status Failed
    return $false
}

function Install-NvmOffline {
    Write-Log "nvm-windows 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "nvm-setup.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "nvm 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "nvm-windows" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Log "nvm-windows 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "nvm-windows" -Status Success
            return $true
        }
    } catch {
        Write-Log "nvm-windows 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "nvm-windows" -Status Failed
    return $false
}

function Install-PythonOffline {
    Write-Log "Python 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "python-3.12.1-amd64.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "Python 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "Python" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Log "Python 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "Python" -Status Success
            return $true
        }
    } catch {
        Write-Log "Python 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "Python" -Status Failed
    return $false
}

function Install-VSCodeOffline {
    Write-Log "VS Code 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "VSCodeSetup-x64.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "VS Code 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "VS Code" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Log "VS Code 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "VS Code" -Status Success
            return $true
        }
    } catch {
        Write-Log "VS Code 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "VS Code" -Status Failed
    return $false
}

function Install-OpenJDKOffline {
    Write-Log "OpenJDK 오프라인 설치 중..." -Level INFO
    
    $archivePath = Join-Path $InstallersDir "openjdk-17.0.2_windows-x64_bin.zip"
    $javaHome = "C:\Program Files\Java\jdk-17.0.2"
    
    if (-not (Test-Path $archivePath)) {
        Write-Log "OpenJDK 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "OpenJDK" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        # 압축 해제
        $extractPath = "C:\Program Files\Java"
        if (-not (Test-Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        }
        
        Expand-Archive -Path $archivePath -DestinationPath $extractPath -Force
        
        # JAVA_HOME 환경 변수 설정
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
        
        # PATH에 추가
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        if ($currentPath -notlike "*$javaHome\bin*") {
            [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$javaHome\bin", "Machine")
        }
        
        $env:JAVA_HOME = $javaHome
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Log "OpenJDK 설치 완료" -Level SUCCESS
        Add-InstallResult -ToolName "OpenJDK" -Status Success
        return $true
    } catch {
        Write-Log "OpenJDK 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "OpenJDK" -Status Failed
    return $false
}

function Install-DockerOffline {
    Write-Log "Docker Desktop 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "Docker-Desktop-Installer.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "Docker Desktop 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "Docker Desktop" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        Write-Log "Docker Desktop 설치는 시간이 걸릴 수 있습니다..." -Level INFO
        $process = Start-Process -FilePath $installerPath -ArgumentList "install --quiet --accept-license" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Docker Desktop 설치 완료 (재시작 필요)" -Level SUCCESS
            Add-InstallResult -ToolName "Docker Desktop" -Status Success
            return $true
        }
    } catch {
        Write-Log "Docker Desktop 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "Docker Desktop" -Status Failed
    return $false
}

function Install-PostgreSQLOffline {
    Write-Log "PostgreSQL 오프라인 설치 중..." -Level INFO
    
    $installerPath = Join-Path $InstallersDir "postgresql-16.1-1-windows-x64.exe"
    
    if (-not (Test-Path $installerPath)) {
        Write-Log "PostgreSQL 설치 파일을 찾을 수 없습니다." -Level ERROR
        Add-InstallResult -ToolName "PostgreSQL" -Status Failed -Message "설치 파일 없음"
        return $false
    }
    
    try {
        $process = Start-Process -FilePath $installerPath -ArgumentList "--mode unattended --superpassword postgres --serverport 5432" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "PostgreSQL 설치 완료" -Level SUCCESS
            Add-InstallResult -ToolName "PostgreSQL" -Status Success
            return $true
        }
    } catch {
        Write-Log "PostgreSQL 설치 실패: $($_.Exception.Message)" -Level ERROR
    }
    
    Add-InstallResult -ToolName "PostgreSQL" -Status Failed
    return $false
}

# ============================================
# 오프라인 전체 설치
# ============================================

function Start-OfflineFullInstall {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              오프라인 전체 설치                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Initialize-InstallResults
    
    # 사용 가능한 설치 파일 확인
    Write-Log "캐시된 설치 파일 확인 중..." -Level INFO
    
    $installSteps = @(
        @{Name="Git"; Function={Install-GitOffline}},
        @{Name="Node.js"; Function={Install-NodeJSOffline}},
        @{Name="Python"; Function={Install-PythonOffline}},
        @{Name="VS Code"; Function={Install-VSCodeOffline}},
        @{Name="OpenJDK"; Function={Install-OpenJDKOffline}},
        @{Name="Docker Desktop"; Function={Install-DockerOffline}},
        @{Name="PostgreSQL"; Function={Install-PostgreSQLOffline}}
    )
    
    $totalSteps = $installSteps.Count
    $currentStep = 0
    
    foreach ($step in $installSteps) {
        $currentStep++
        Write-Host ""
        Write-Host "[$currentStep/$totalSteps] $($step.Name) 설치 중..." -ForegroundColor Yellow
        
        & $step.Function
    }
    
    Write-Host ""
    Show-InstallSummary
}

function Start-OfflineSelectiveInstall {
    Write-Host ""
    Write-Host "설치할 도구를 선택하세요:" -ForegroundColor Cyan
    Write-Host ""
    
    Initialize-InstallResults
    
    $tools = @(
        @{Name="Git"; Function={Install-GitOffline}; File="Git-2.43.0-64-bit.exe"},
        @{Name="Node.js"; Function={Install-NodeJSOffline}; File="node-v22.12.0-x64.msi"},
        @{Name="nvm-windows"; Function={Install-NvmOffline}; File="nvm-setup.exe"},
        @{Name="Python"; Function={Install-PythonOffline}; File="python-3.12.1-amd64.exe"},
        @{Name="VS Code"; Function={Install-VSCodeOffline}; File="VSCodeSetup-x64.exe"},
        @{Name="OpenJDK"; Function={Install-OpenJDKOffline}; File="openjdk-17.0.2_windows-x64_bin.zip"},
        @{Name="Docker Desktop"; Function={Install-DockerOffline}; File="Docker-Desktop-Installer.exe"},
        @{Name="PostgreSQL"; Function={Install-PostgreSQLOffline}; File="postgresql-16.1-1-windows-x64.exe"}
    )
    
    foreach ($tool in $tools) {
        $cached = Test-Path (Join-Path $InstallersDir $tool.File)
        $status = if ($cached) { "[캐시됨]" } else { "[없음]" }
        $color = if ($cached) { "Green" } else { "Red" }
        
        Write-Host "  $($tool.Name) " -NoNewline
        Write-Host $status -ForegroundColor $color
        
        if ($cached) {
            $response = Read-Host "  $($tool.Name) 설치? (Y/N)"
            if ($response -eq 'Y' -or $response -eq 'y') {
                & $tool.Function
            }
        }
    }
    
    Write-Host ""
    Show-InstallSummary
}

# ============================================
# 메뉴
# ============================================

function Show-OfflineMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    오프라인 설치 모드" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 전체 설치 (캐시된 모든 도구)" -ForegroundColor White
    Write-Host "  [2] 선택적 설치" -ForegroundColor White
    Write-Host "  [3] 캐시 상태 확인" -ForegroundColor White
    Write-Host "  [4] 캐시 매니저 열기" -ForegroundColor Yellow
    Write-Host "  [0] 종료" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Start-OfflineInstaller {
    # 오프라인 모드 확인
    if (-not (Test-OfflineMode)) {
        Write-Host ""
        $response = Read-Host "캐시 매니저를 열어 패키지를 다운로드하시겠습니까? (Y/N)"
        if ($response -eq 'Y' -or $response -eq 'y') {
            & "$PSScriptRoot\cache-manager.ps1"
        }
        return
    }
    
    while ($true) {
        Show-OfflineMenu
        $choice = Read-Host "선택 (0-4)"
        
        switch ($choice) {
            "1" { Start-OfflineFullInstall }
            "2" { Start-OfflineSelectiveInstall }
            "3" { 
                . "$PSScriptRoot\cache-manager.ps1"
                Show-CacheStatus 
            }
            "4" { & "$PSScriptRoot\cache-manager.ps1" }
            "0" { 
                Write-Log "오프라인 설치를 종료합니다." -Level INFO
                return 
            }
            default { Write-Log "잘못된 선택입니다." -Level WARNING }
        }
        
        Write-Host ""
        Read-Host "계속하려면 Enter를 누르세요..."
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Start-OfflineInstaller
}
