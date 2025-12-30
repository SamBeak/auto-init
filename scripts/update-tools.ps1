# ============================================
# 도구 업데이트 스크립트
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

. "$PSScriptRoot\utils.ps1"

$ScriptRoot = Split-Path -Parent $PSScriptRoot

# ============================================
# 업데이트 가능 도구 확인
# ============================================

function Get-InstalledToolVersions {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              설치된 도구 버전 확인                            ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $tools = @()
    
    # Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        $version = (choco --version).Trim()
        $tools += [PSCustomObject]@{ Name = "Chocolatey"; Version = $version; UpdateCmd = "choco upgrade chocolatey -y" }
    }
    
    # Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $version = (git --version).Replace("git version ", "").Trim()
        $tools += [PSCustomObject]@{ Name = "Git"; Version = $version; UpdateCmd = "choco upgrade git -y" }
    }
    
    # Node.js
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $version = (node --version).Trim()
        $tools += [PSCustomObject]@{ Name = "Node.js"; Version = $version; UpdateCmd = "nvm install latest" }
    }
    
    # Python
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $version = (python --version).Replace("Python ", "").Trim()
        $tools += [PSCustomObject]@{ Name = "Python"; Version = $version; UpdateCmd = "choco upgrade python -y" }
    }
    
    # Java
    if (Get-Command java -ErrorAction SilentlyContinue) {
        $versionOutput = java -version 2>&1 | Select-Object -First 1
        $version = $versionOutput -replace '.*"(.+)".*', '$1'
        $tools += [PSCustomObject]@{ Name = "Java"; Version = $version; UpdateCmd = "choco upgrade openjdk -y" }
    }
    
    # Docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $version = (docker --version).Replace("Docker version ", "").Split(",")[0].Trim()
        $tools += [PSCustomObject]@{ Name = "Docker"; Version = $version; UpdateCmd = "choco upgrade docker-desktop -y" }
    }
    
    # VS Code
    if (Get-Command code -ErrorAction SilentlyContinue) {
        $version = (code --version | Select-Object -First 1).Trim()
        $tools += [PSCustomObject]@{ Name = "VS Code"; Version = $version; UpdateCmd = "choco upgrade vscode -y" }
    }
    
    # npm
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $version = (npm --version).Trim()
        $tools += [PSCustomObject]@{ Name = "npm"; Version = "v$version"; UpdateCmd = "npm install -g npm@latest" }
    }
    
    # yarn
    if (Get-Command yarn -ErrorAction SilentlyContinue) {
        $version = (yarn --version).Trim()
        $tools += [PSCustomObject]@{ Name = "Yarn"; Version = "v$version"; UpdateCmd = "npm install -g yarn@latest" }
    }
    
    # pnpm
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $version = (pnpm --version).Trim()
        $tools += [PSCustomObject]@{ Name = "pnpm"; Version = "v$version"; UpdateCmd = "npm install -g pnpm@latest" }
    }
    
    return $tools
}

function Show-ToolVersions {
    param([array]$Tools)
    
    Write-Host "┌────────────────────┬────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│ 도구               │ 버전               │" -ForegroundColor DarkCyan
    Write-Host "├────────────────────┼────────────────────┤" -ForegroundColor DarkCyan
    
    foreach ($tool in $Tools) {
        $name = $tool.Name.PadRight(18)
        $version = $tool.Version.PadRight(18)
        Write-Host "│ $name │ $version │" -ForegroundColor White
    }
    
    Write-Host "└────────────────────┴────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

# ============================================
# 업데이트 실행
# ============================================

function Update-AllChocolateyPackages {
    Write-Log "모든 Chocolatey 패키지 업데이트 중..." -Level INFO
    
    try {
        choco upgrade all -y
        Write-Log "Chocolatey 패키지 업데이트 완료" -Level SUCCESS
        return $true
    } catch {
        Write-Log "업데이트 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-NpmPackages {
    Write-Log "전역 npm 패키지 업데이트 중..." -Level INFO
    
    try {
        npm update -g
        Write-Log "npm 패키지 업데이트 완료" -Level SUCCESS
        return $true
    } catch {
        Write-Log "업데이트 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-SelectedTool {
    param(
        [PSCustomObject]$Tool
    )
    
    Write-Log "$($Tool.Name) 업데이트 중..." -Level INFO
    
    try {
        Invoke-Expression $Tool.UpdateCmd
        Write-Log "$($Tool.Name) 업데이트 완료" -Level SUCCESS
        return $true
    } catch {
        Write-Log "$($Tool.Name) 업데이트 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================
# 업데이트 메뉴
# ============================================

function Show-UpdateMenu {
    param([array]$Tools)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    업데이트 옵션" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 모든 Chocolatey 패키지 업데이트" -ForegroundColor White
    Write-Host "  [2] 전역 npm 패키지 업데이트" -ForegroundColor White
    Write-Host "  [3] 개별 도구 선택 업데이트" -ForegroundColor White
    Write-Host "  [4] 전체 업데이트 (권장)" -ForegroundColor Green
    Write-Host "  [0] 돌아가기" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "선택"
    
    switch ($choice) {
        "1" { Update-AllChocolateyPackages }
        "2" { Update-NpmPackages }
        "3" {
            Write-Host ""
            for ($i = 0; $i -lt $Tools.Count; $i++) {
                Write-Host "  [$($i + 1)] $($Tools[$i].Name) ($($Tools[$i].Version))" -ForegroundColor White
            }
            Write-Host ""
            $toolChoice = Read-Host "업데이트할 도구 번호"
            $index = [int]$toolChoice - 1
            if ($index -ge 0 -and $index -lt $Tools.Count) {
                Update-SelectedTool -Tool $Tools[$index]
            }
        }
        "4" {
            Update-AllChocolateyPackages
            Update-NpmPackages
        }
        "0" { return }
    }
}

# ============================================
# 메인 실행
# ============================================

function Start-UpdateMode {
    $tools = Get-InstalledToolVersions
    Show-ToolVersions -Tools $tools
    Show-UpdateMenu -Tools $tools
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-UpdateMode
}
