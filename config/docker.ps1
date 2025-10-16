# ============================================
# Docker Desktop 및 WSL2 설치
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-WSL2 {
    Write-Log "WSL2 설치를 시작합니다..." -Level INFO

    # WSL이 이미 설치되어 있는지 확인
    $wslVersion = wsl --version 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Log "WSL이 이미 설치되어 있습니다." -Level SUCCESS
        Write-Log "$wslVersion" -Level INFO
        return $true
    }

    try {
        # WSL 기능 활성화
        Write-Log "WSL 기능 활성화 중..." -Level INFO
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

        # Virtual Machine Platform 활성화
        Write-Log "Virtual Machine Platform 활성화 중..." -Level INFO
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

        # WSL2를 기본값으로 설정
        wsl --set-default-version 2

        Write-Log "WSL2 설치 완료. 시스템 재시작이 필요합니다." -Level SUCCESS
        return $true

    } catch {
        Write-Log "WSL2 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-UbuntuWSL {
    Write-Log "Ubuntu WSL 배포판 설치를 시작합니다..." -Level INFO

    # Ubuntu가 이미 설치되어 있는지 확인
    $installedDistros = wsl --list 2>&1

    if ($installedDistros -like "*Ubuntu*") {
        Write-Log "Ubuntu가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    try {
        # Microsoft Store를 통한 Ubuntu 설치 (winget 사용)
        winget install Canonical.Ubuntu.2204 --accept-package-agreements --accept-source-agreements --silent

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Ubuntu WSL 설치 완료" -Level SUCCESS
            Write-Log "Ubuntu를 실행하여 초기 설정을 완료하세요." -Level INFO
            return $true
        } else {
            Write-Log "Ubuntu WSL 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Ubuntu WSL 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-DockerDesktop {
    Write-Log "Docker Desktop 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Docker Desktop") {
        Write-Log "Docker Desktop이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # WSL2가 설치되어 있는지 확인
    if (-not (Test-ProgramInstalled -CommandCheck "wsl")) {
        Write-Log "Docker Desktop 설치 전 WSL2를 먼저 설치합니다." -Level INFO
        Install-WSL2
    }

    # Chocolatey로 Docker Desktop 설치
    $result = Install-ChocolateyPackage -PackageName "docker-desktop"

    if ($result) {
        Write-Log "Docker Desktop 설치 완료" -Level SUCCESS
        Write-Log "Docker Desktop을 실행하여 초기 설정을 완료하세요." -Level INFO
        return $true
    }

    return $false
}

function Install-DockerCompose {
    Write-Log "Docker Compose 확인 중..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "docker-compose") {
        $version = docker-compose --version
        Write-Log "Docker Compose가 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    # Docker Desktop에 포함된 Docker Compose 확인
    try {
        $version = docker compose version
        Write-Log "Docker Compose (Docker Desktop 포함) 사용 가능: $version" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Docker Compose를 찾을 수 없습니다." -Level WARNING
        return $false
    }
}

function Set-DockerConfiguration {
    Write-Log "Docker 설정 구성 중..." -Level INFO

    try {
        # Docker가 실행 중인지 확인
        $dockerRunning = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue

        if (-not $dockerRunning) {
            Write-Log "Docker Desktop이 실행되고 있지 않습니다." -Level WARNING
            return $false
        }

        # Docker 정보 확인
        $dockerInfo = docker info 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker가 정상적으로 실행 중입니다." -Level SUCCESS
            return $true
        } else {
            Write-Log "Docker 상태 확인 실패" -Level WARNING
            return $false
        }

    } catch {
        Write-Log "Docker 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-WSL2
    Install-UbuntuWSL
    Install-DockerDesktop
    Install-DockerCompose
    Set-DockerConfiguration
}
