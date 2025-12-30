# ============================================
# 백업 및 복원 스크립트
# ============================================

. "$PSScriptRoot\utils.ps1"

$global:BackupDir = Join-Path $PSScriptRoot "..\data\backup"

function New-BackupDirectory {
    if (-not (Test-Path $global:BackupDir)) {
        New-Item -ItemType Directory -Path $global:BackupDir -Force | Out-Null
        Write-Log "백업 디렉토리 생성: $global:BackupDir" -Level INFO
    }
}

function Backup-VSCodeSettings {
    Write-Log "VS Code 설정 백업 중..." -Level INFO

    $settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
    $keybindingsPath = Join-Path $env:APPDATA "Code\User\keybindings.json"
    $snippetsPath = Join-Path $env:APPDATA "Code\User\snippets"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $global:BackupDir "vscode_$timestamp"

    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    try {
        # settings.json 백업
        if (Test-Path $settingsPath) {
            Copy-Item -Path $settingsPath -Destination (Join-Path $backupPath "settings.json") -Force
            Write-Log "settings.json 백업 완료" -Level SUCCESS
        }

        # keybindings.json 백업
        if (Test-Path $keybindingsPath) {
            Copy-Item -Path $keybindingsPath -Destination (Join-Path $backupPath "keybindings.json") -Force
            Write-Log "keybindings.json 백업 완료" -Level SUCCESS
        }

        # snippets 백업
        if (Test-Path $snippetsPath) {
            Copy-Item -Path $snippetsPath -Destination (Join-Path $backupPath "snippets") -Recurse -Force
            Write-Log "snippets 백업 완료" -Level SUCCESS
        }

        # 확장 목록 백업
        if (Test-ProgramInstalled -CommandCheck "code") {
            $extensions = code --list-extensions
            $extensions | Out-File -FilePath (Join-Path $backupPath "extensions.txt") -Encoding UTF8
            Write-Log "확장 목록 백업 완료" -Level SUCCESS
        }

        Write-Log "VS Code 설정 백업 완료: $backupPath" -Level SUCCESS
        return $backupPath

    } catch {
        Write-Log "VS Code 설정 백업 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Backup-GitConfig {
    Write-Log "Git 설정 백업 중..." -Level INFO

    $gitConfigPath = Join-Path $env:USERPROFILE ".gitconfig"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $global:BackupDir "gitconfig_$timestamp"

    try {
        if (Test-Path $gitConfigPath) {
            Copy-Item -Path $gitConfigPath -Destination $backupPath -Force
            Write-Log "Git 설정 백업 완료: $backupPath" -Level SUCCESS
            return $backupPath
        } else {
            Write-Log "Git 설정 파일을 찾을 수 없습니다." -Level WARNING
            return $null
        }

    } catch {
        Write-Log "Git 설정 백업 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Backup-PowerShellProfile {
    Write-Log "PowerShell 프로필 백업 중..." -Level INFO

    $profilePath = $PROFILE.CurrentUserAllHosts
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $global:BackupDir "ps_profile_$timestamp.ps1"

    try {
        if (Test-Path $profilePath) {
            Copy-Item -Path $profilePath -Destination $backupPath -Force
            Write-Log "PowerShell 프로필 백업 완료: $backupPath" -Level SUCCESS
            return $backupPath
        } else {
            Write-Log "PowerShell 프로필을 찾을 수 없습니다." -Level WARNING
            return $null
        }

    } catch {
        Write-Log "PowerShell 프로필 백업 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Backup-NpmConfig {
    Write-Log "npm 설정 백업 중..." -Level INFO

    $npmrcPath = Join-Path $env:USERPROFILE ".npmrc"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $global:BackupDir "npmrc_$timestamp"

    try {
        if (Test-Path $npmrcPath) {
            Copy-Item -Path $npmrcPath -Destination $backupPath -Force
            Write-Log "npm 설정 백업 완료: $backupPath" -Level SUCCESS
            return $backupPath
        } else {
            Write-Log "npm 설정 파일을 찾을 수 없습니다." -Level WARNING
            return $null
        }

    } catch {
        Write-Log "npm 설정 백업 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Backup-AllConfigurations {
    Write-Log "모든 설정 백업을 시작합니다..." -Level INFO

    New-BackupDirectory

    $backupResults = @()

    # VS Code
    $vscodeBackup = Backup-VSCodeSettings
    if ($vscodeBackup) {
        $backupResults += "VS Code: $vscodeBackup"
    }

    # Git
    $gitBackup = Backup-GitConfig
    if ($gitBackup) {
        $backupResults += "Git: $gitBackup"
    }

    # PowerShell
    $psBackup = Backup-PowerShellProfile
    if ($psBackup) {
        $backupResults += "PowerShell: $psBackup"
    }

    # npm
    $npmBackup = Backup-NpmConfig
    if ($npmBackup) {
        $backupResults += "npm: $npmBackup"
    }

    # 백업 목록 저장
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $manifestPath = Join-Path $global:BackupDir "backup_manifest_$timestamp.txt"
    $backupResults | Out-File -FilePath $manifestPath -Encoding UTF8

    Write-Log "`n백업 완료! 총 $($backupResults.Count)개 항목" -Level SUCCESS
    Write-Log "백업 위치: $global:BackupDir" -Level INFO
    Write-Log "백업 목록: $manifestPath" -Level INFO
}

function Restore-VSCodeSettings {
    param(
        [string]$BackupPath
    )

    Write-Log "VS Code 설정 복원 중..." -Level INFO

    if (-not (Test-Path $BackupPath)) {
        Write-Log "백업 경로를 찾을 수 없습니다: $BackupPath" -Level ERROR
        return $false
    }

    $settingsPath = Join-Path $env:APPDATA "Code\User"

    try {
        # settings.json 복원
        $settingsBackup = Join-Path $BackupPath "settings.json"
        if (Test-Path $settingsBackup) {
            Copy-Item -Path $settingsBackup -Destination (Join-Path $settingsPath "settings.json") -Force
            Write-Log "settings.json 복원 완료" -Level SUCCESS
        }

        # keybindings.json 복원
        $keybindingsBackup = Join-Path $BackupPath "keybindings.json"
        if (Test-Path $keybindingsBackup) {
            Copy-Item -Path $keybindingsBackup -Destination (Join-Path $settingsPath "keybindings.json") -Force
            Write-Log "keybindings.json 복원 완료" -Level SUCCESS
        }

        # snippets 복원
        $snippetsBackup = Join-Path $BackupPath "snippets"
        if (Test-Path $snippetsBackup) {
            Copy-Item -Path $snippetsBackup -Destination (Join-Path $settingsPath "snippets") -Recurse -Force
            Write-Log "snippets 복원 완료" -Level SUCCESS
        }

        # 확장 복원
        $extensionsBackup = Join-Path $BackupPath "extensions.txt"
        if (Test-Path $extensionsBackup) {
            $extensions = Get-Content $extensionsBackup
            foreach ($ext in $extensions) {
                code --install-extension $ext --force
            }
            Write-Log "확장 복원 완료" -Level SUCCESS
        }

        Write-Log "VS Code 설정 복원 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "VS Code 설정 복원 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Show-BackupList {
    Write-Log "백업 목록:" -Level INFO

    if (-not (Test-Path $global:BackupDir)) {
        Write-Log "백업이 없습니다." -Level WARNING
        return
    }

    $backups = Get-ChildItem -Path $global:BackupDir -Directory | Sort-Object Name -Descending

    if ($backups.Count -eq 0) {
        Write-Log "백업이 없습니다." -Level WARNING
        return
    }

    $i = 1
    foreach ($backup in $backups) {
        Write-Host "  [$i] $($backup.Name) - $($backup.LastWriteTime)" -ForegroundColor Cyan
        $i++
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "`n백업/복원 도구`n" -ForegroundColor Cyan
    Write-Host "[1] 모든 설정 백업" -ForegroundColor White
    Write-Host "[2] 백업 목록 보기" -ForegroundColor White
    Write-Host "[3] VS Code 설정 백업" -ForegroundColor White
    Write-Host "[4] Git 설정 백업" -ForegroundColor White
    Write-Host "[0] 종료`n" -ForegroundColor Red

    $choice = Read-Host "선택"

    switch ($choice) {
        "1" { Backup-AllConfigurations }
        "2" { Show-BackupList }
        "3" { Backup-VSCodeSettings }
        "4" { Backup-GitConfig }
        "0" { exit }
        default { Write-Log "잘못된 선택입니다." -Level WARNING }
    }
}
