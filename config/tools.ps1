# ============================================
# 추가 개발 도구 설치
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"
. "$PSScriptRoot\winget.ps1"

function Install-Postman {
    Write-Log "Postman 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Postman") {
        Write-Log "Postman이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "postman"

    if ($result) {
        Write-Log "Postman 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-HeidiSQL {
    Write-Log "HeidiSQL 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "HeidiSQL") {
        Write-Log "HeidiSQL이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "heidisql"

    if ($result) {
        Write-Log "HeidiSQL 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-NotepadPlusPlus {
    Write-Log "Notepad++ 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Notepad++") {
        Write-Log "Notepad++이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "notepadplusplus"

    if ($result) {
        Write-Log "Notepad++ 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-Figma {
    Write-Log "Figma 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Figma") {
        Write-Log "Figma가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Winget으로 설치
    if (Test-WingetAvailable) {
        $result = Install-WingetPackage -PackageId "Figma.Figma"

        if ($result) {
            Write-Log "Figma 설치 완료" -Level SUCCESS
            return $true
        }
    } else {
        Write-Log "Winget을 사용할 수 없습니다. 수동 설치가 필요합니다." -Level WARNING
        Write-Log "다운로드: https://www.figma.com/downloads/" -Level INFO
        return $false
    }

    return $false
}

function Install-OhMyPosh {
    Write-Log "Oh My Posh 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "oh-my-posh") {
        $version = oh-my-posh --version
        Write-Log "Oh My Posh가 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    # Winget으로 설치
    if (Test-WingetAvailable) {
        $result = Install-WingetPackage -PackageId "JanDeDobbeleer.OhMyPosh"

        if ($result) {
            # 환경 변수 새로고침
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            Write-Log "Oh My Posh 설치 완료" -Level SUCCESS

            # 폰트 설치 안내
            Write-Log "Nerd Font를 설치하려면: oh-my-posh font install" -Level INFO
            return $true
        }
    } else {
        # Chocolatey 대체
        $result = Install-ChocolateyPackage -PackageName "oh-my-posh"
        if ($result) {
            Write-Log "Oh My Posh 설치 완료" -Level SUCCESS
            return $true
        }
    }

    return $false
}

function Set-OhMyPoshProfile {
    Write-Log "Oh My Posh PowerShell 프로필 설정 중..." -Level INFO

    if (-not (Test-ProgramInstalled -CommandCheck "oh-my-posh")) {
        Write-Log "Oh My Posh가 설치되어 있지 않습니다." -Level WARNING
        return $false
    }

    try {
        # PowerShell 프로필 경로
        $profilePath = $PROFILE.CurrentUserAllHosts

        # 프로필 디렉토리 생성
        $profileDir = Split-Path $profilePath -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        # 기존 프로필 백업
        if (Test-Path $profilePath) {
            Backup-Configuration -ConfigPath $profilePath
        }

        # Oh My Posh 초기화 코드 추가
        $ohMyPoshInit = @"
# Oh My Posh 초기화
oh-my-posh init pwsh --config `$env:POSH_THEMES_PATH\robbyrussell.omp.json | Invoke-Expression
"@

        # 프로필에 추가 (중복 방지)
        $currentProfile = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { "" }

        if ($currentProfile -notlike "*oh-my-posh init*") {
            Add-Content -Path $profilePath -Value "`n$ohMyPoshInit"
            Write-Log "Oh My Posh가 PowerShell 프로필에 추가되었습니다." -Level SUCCESS
        } else {
            Write-Log "Oh My Posh가 이미 프로필에 설정되어 있습니다." -Level INFO
        }

        return $true

    } catch {
        Write-Log "Oh My Posh 프로필 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-WindowsTerminal {
    Write-Log "Windows Terminal 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Windows Terminal") {
        Write-Log "Windows Terminal이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Winget으로 설치
    if (Test-WingetAvailable) {
        $result = Install-WingetPackage -PackageId "Microsoft.WindowsTerminal"

        if ($result) {
            Write-Log "Windows Terminal 설치 완료" -Level SUCCESS
            return $true
        }
    } else {
        Write-Log "Winget을 사용할 수 없습니다. Microsoft Store에서 수동 설치하세요." -Level WARNING
        return $false
    }

    return $false
}

function Install-PowerShell7 {
    Write-Log "PowerShell 7 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "pwsh") {
        $version = pwsh --version
        Write-Log "PowerShell 7이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "powershell-core"

    if ($result) {
        Write-Log "PowerShell 7 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-Browsers {
    Write-Log "웹 브라우저 설치 중..." -Level INFO

    # Google Chrome
    if (-not (Test-ProgramInstalled -ProgramName "Google Chrome")) {
        Install-ChocolateyPackage -PackageName "googlechrome"
    }

    # Microsoft Edge (보통 기본 설치됨)
    if (-not (Test-ProgramInstalled -ProgramName "Microsoft Edge")) {
        Write-Log "Microsoft Edge는 Windows에 기본 설치되어 있습니다." -Level INFO
    }

    # Firefox (선택사항)
    # Install-ChocolateyPackage -PackageName "firefox"

    Write-Log "브라우저 설치 완료" -Level SUCCESS
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-PowerShell7
    Install-WindowsTerminal
    Install-OhMyPosh
    Set-OhMyPoshProfile
    Install-Postman
    Install-HeidiSQL
    Install-NotepadPlusPlus
    Install-Figma
    Install-Browsers
}
