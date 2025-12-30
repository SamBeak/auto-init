# ============================================
# Python 설치 및 설정
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-Python {
    param(
        [string]$Version = "3"  # 3 또는 특정 버전
    )

    Write-Log "Python 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "python") {
        $currentVersion = python --version
        Write-Log "Python이 이미 설치되어 있습니다: $currentVersion" -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "python" -Params @("/InstallDir:C:\Python3")

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $pythonVersion = python --version
        $pipVersion = pip --version

        Write-Log "Python 설치 완료: $pythonVersion" -Level SUCCESS
        Write-Log "pip 버전: $pipVersion" -Level INFO
        return $true
    }

    return $false
}

function Install-Pipx {
    Write-Log "pipx 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "pipx") {
        $version = pipx --version
        Write-Log "pipx가 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    try {
        python -m pip install --user pipx
        python -m pipx ensurepath

        Write-Log "pipx 설치 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "pipx 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-Poetry {
    Write-Log "Poetry 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "poetry") {
        $version = poetry --version
        Write-Log "Poetry가 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    try {
        (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -

        # Poetry PATH 추가 (Poetry는 %APPDATA%\pypoetry\venv\Scripts에 설치됨)
        $poetryPath = Join-Path $env:APPDATA "pypoetry\venv\Scripts"
        Add-PathVariable -Path $poetryPath -Scope User
        
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "Poetry 설치 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "Poetry 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-GlobalPipPackages {
    Write-Log "전역 pip 패키지 설치 중..." -Level INFO

    $packages = @(
        "virtualenv",
        "black",
        "flake8",
        "pylint",
        "pytest",
        "jupyter",
        "ipython",
        "requests",
        "python-dotenv"
    )

    $successCount = 0
    $failCount = 0

    foreach ($package in $packages) {
        try {
            Write-Log "설치 중: $package" -Level INFO
            pip install $package --quiet

            if ($LASTEXITCODE -eq 0) {
                Write-Log "$package 설치 완료" -Level SUCCESS
                $successCount++
            } else {
                Write-Log "$package 설치 실패" -Level ERROR
                $failCount++
            }

        } catch {
            Write-Log "$package 설치 중 오류: $($_.Exception.Message)" -Level ERROR
            $failCount++
        }
    }

    Write-Log "전역 패키지 설치 완료 (성공: $successCount, 실패: $failCount)" -Level INFO
    return ($failCount -eq 0)
}

function Set-PythonConfiguration {
    Write-Log "Python 설정 구성 중..." -Level INFO

    try {
        # pip 업그레이드
        python -m pip install --upgrade pip

        # pip 설정
        pip config set global.timeout 60
        pip config set global.retries 3

        Write-Log "Python 설정 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "Python 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    $pythonResult = Install-Python
    if ($pythonResult) {
        Add-InstallResult -ToolName "Python" -Status Success
    } else {
        Add-InstallResult -ToolName "Python" -Status Failed -Message "설치 실패"
    }
    
    $pipxResult = Install-Pipx
    if ($pipxResult) {
        Add-InstallResult -ToolName "pipx" -Status Success
    } else {
        Add-InstallResult -ToolName "pipx" -Status Failed -Message "설치 실패"
    }
    
    $poetryResult = Install-Poetry
    if ($poetryResult) {
        Add-InstallResult -ToolName "Poetry" -Status Success
    } else {
        Add-InstallResult -ToolName "Poetry" -Status Failed -Message "설치 실패"
    }
    
    Install-GlobalPipPackages
    Set-PythonConfiguration
}
