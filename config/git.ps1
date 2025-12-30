# ============================================
# Git 설치 및 설정
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-Git {
    Write-Log "Git 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "git") {
        $version = git --version
        Write-Log "Git이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "git" -Params @("/GitAndUnixToolsOnPath", "/NoAutoCrlf")

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "Git 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Set-GitConfiguration {
    param(
        [string]$UserName,
        [string]$UserEmail
    )

    Write-Log "Git 전역 설정을 구성합니다..." -Level INFO

    if (-not (Test-ProgramInstalled -CommandCheck "git")) {
        Write-Log "Git이 설치되어 있지 않습니다." -Level ERROR
        return $false
    }

    try {
        # 사용자 정보 설정
        if ($UserName) {
            git config --global user.name "$UserName"
            Write-Log "Git user.name 설정: $UserName" -Level SUCCESS
        }

        if ($UserEmail) {
            git config --global user.email "$UserEmail"
            Write-Log "Git user.email 설정: $UserEmail" -Level SUCCESS
        }

        # 기본 브랜치명 설정
        git config --global init.defaultBranch main

        # 줄바꿈 설정 (Windows)
        git config --global core.autocrlf true

        # 대소문자 구분
        git config --global core.ignorecase false

        # 기본 에디터 설정 (VS Code)
        if (Test-ProgramInstalled -CommandCheck "code") {
            git config --global core.editor "code --wait"
        }

        # Pull 전략 설정
        git config --global pull.rebase false

        # 색상 설정
        git config --global color.ui auto

        # Credential helper
        git config --global credential.helper manager-core

        Write-Log "Git 전역 설정 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "Git 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-GitHubCLI {
    Write-Log "GitHub CLI 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "gh") {
        $version = gh --version
        Write-Log "GitHub CLI가 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    $result = Install-ChocolateyPackage -PackageName "gh"

    if ($result) {
        Write-Log "GitHub CLI 설치 완료" -Level SUCCESS
        Write-Log "인증: gh auth login" -Level INFO
        return $true
    }

    return $false
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    $gitResult = Install-Git
    if ($gitResult) {
        Add-InstallResult -ToolName "Git" -Status Success
    } else {
        Add-InstallResult -ToolName "Git" -Status Failed -Message "설치 실패"
    }
    
    $ghResult = Install-GitHubCLI
    if ($ghResult) {
        Add-InstallResult -ToolName "GitHub CLI" -Status Success
    } else {
        Add-InstallResult -ToolName "GitHub CLI" -Status Failed -Message "설치 실패"
    }
}
