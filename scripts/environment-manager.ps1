# ============================================
# 환경 내보내기/가져오기 및 프로필 관리
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ProfilesDir = Join-Path $ScriptRoot "profiles"

# ============================================
# 디렉토리 초기화
# ============================================

function Initialize-ProfilesDirectory {
    if (-not (Test-Path $ProfilesDir)) {
        New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null
        Write-Log "프로필 디렉토리 생성: $ProfilesDir" -Level INFO
    }
}

# ============================================
# 환경 내보내기
# ============================================

function Export-Environment {
    param(
        [string]$OutputPath = ""
    )
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              환경 내보내기                                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $environment = @{
        ExportedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        MachineName = $env:COMPUTERNAME
        WindowsVersion = [System.Environment]::OSVersion.Version.ToString()
        Tools = @{}
        GlobalPackages = @{}
        VSCodeExtensions = @()
        EnvironmentVariables = @{}
    }
    
    # 도구 버전 수집
    Write-Log "설치된 도구 정보 수집 중..." -Level INFO
    
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $environment.Tools.Git = (git --version).Replace("git version ", "").Trim()
    }
    
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $environment.Tools.NodeJS = (node --version).Trim()
    }
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $environment.Tools.Python = (python --version).Replace("Python ", "").Trim()
    }
    
    if (Get-Command java -ErrorAction SilentlyContinue) {
        $javaVersion = java -version 2>&1 | Select-Object -First 1
        $environment.Tools.Java = $javaVersion -replace '.*"(.+)".*', '$1'
    }
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $environment.Tools.Docker = (docker --version).Replace("Docker version ", "").Split(",")[0].Trim()
    }
    
    # 전역 npm 패키지 수집
    Write-Log "전역 npm 패키지 수집 중..." -Level INFO
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            $npmList = npm list -g --depth=0 --json 2>$null | ConvertFrom-Json
            if ($npmList.dependencies) {
                $environment.GlobalPackages.npm = $npmList.dependencies.PSObject.Properties | ForEach-Object {
                    @{ Name = $_.Name; Version = $_.Value.version }
                }
            }
        } catch {
            Write-Log "npm 패키지 수집 실패" -Level WARNING
        }
    }
    
    # pip 패키지 수집
    Write-Log "전역 pip 패키지 수집 중..." -Level INFO
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        try {
            $pipList = pip list --format=json 2>$null | ConvertFrom-Json
            $environment.GlobalPackages.pip = $pipList | ForEach-Object {
                @{ Name = $_.name; Version = $_.version }
            }
        } catch {
            Write-Log "pip 패키지 수집 실패" -Level WARNING
        }
    }
    
    # VS Code 확장 수집
    Write-Log "VS Code 확장 수집 중..." -Level INFO
    if (Get-Command code -ErrorAction SilentlyContinue) {
        try {
            $extensions = code --list-extensions 2>$null
            $environment.VSCodeExtensions = $extensions
        } catch {
            Write-Log "VS Code 확장 수집 실패" -Level WARNING
        }
    }
    
    # 환경 변수 수집 (개발 관련)
    Write-Log "환경 변수 수집 중..." -Level INFO
    $devEnvVars = @("JAVA_HOME", "PYTHON_HOME", "NODE_PATH", "GOPATH", "CARGO_HOME", "NVM_HOME")
    foreach ($varName in $devEnvVars) {
        $value = [Environment]::GetEnvironmentVariable($varName, "User")
        if ($value) {
            $environment.EnvironmentVariables[$varName] = $value
        }
    }
    
    # 파일 저장
    if ([string]::IsNullOrEmpty($OutputPath)) {
        Initialize-ProfilesDirectory
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = Join-Path $ProfilesDir "environment_$timestamp.json"
    }
    
    $environment | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Log "환경 내보내기 완료: $OutputPath" -Level SUCCESS
    
    # 요약 표시
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│  내보내기 완료                                  │" -ForegroundColor Green
    Write-Host "├─────────────────────────────────────────────────┤" -ForegroundColor Green
    Write-Host "│  도구: $($environment.Tools.Count)개" -ForegroundColor White -NoNewline
    Write-Host (" " * 39) -NoNewline
    Write-Host "│" -ForegroundColor Green
    Write-Host "│  npm 패키지: $($environment.GlobalPackages.npm.Count)개" -ForegroundColor White -NoNewline
    Write-Host (" " * 33) -NoNewline
    Write-Host "│" -ForegroundColor Green
    Write-Host "│  VS Code 확장: $($environment.VSCodeExtensions.Count)개" -ForegroundColor White -NoNewline
    Write-Host (" " * 31) -NoNewline
    Write-Host "│" -ForegroundColor Green
    Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
    
    return $OutputPath
}

# ============================================
# 환경 가져오기
# ============================================

function Import-Environment {
    param(
        [string]$InputPath
    )
    
    if (-not (Test-Path $InputPath)) {
        Write-Log "환경 파일을 찾을 수 없습니다: $InputPath" -Level ERROR
        return $false
    }
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              환경 가져오기                                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $environment = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
        
        Write-Log "환경 파일 로드: $($environment.MachineName) ($($environment.ExportedAt))" -Level INFO
        
        # VS Code 확장 설치
        if ($environment.VSCodeExtensions -and $environment.VSCodeExtensions.Count -gt 0) {
            $installExtensions = Read-Host "VS Code 확장 $($environment.VSCodeExtensions.Count)개를 설치하시겠습니까? (Y/N)"
            
            if ($installExtensions -eq 'Y' -or $installExtensions -eq 'y') {
                foreach ($ext in $environment.VSCodeExtensions) {
                    Write-Log "확장 설치 중: $ext" -Level INFO
                    code --install-extension $ext 2>$null
                }
            }
        }
        
        # npm 패키지 설치
        if ($environment.GlobalPackages.npm -and $environment.GlobalPackages.npm.Count -gt 0) {
            $installNpm = Read-Host "전역 npm 패키지 $($environment.GlobalPackages.npm.Count)개를 설치하시겠습니까? (Y/N)"
            
            if ($installNpm -eq 'Y' -or $installNpm -eq 'y') {
                foreach ($pkg in $environment.GlobalPackages.npm) {
                    Write-Log "npm 설치 중: $($pkg.Name)" -Level INFO
                    npm install -g "$($pkg.Name)@$($pkg.Version)" 2>$null
                }
            }
        }
        
        Write-Log "환경 가져오기 완료" -Level SUCCESS
        return $true
        
    } catch {
        Write-Log "환경 가져오기 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================
# 프로필 저장/불러오기
# ============================================

function Save-InstallProfile {
    param(
        [string]$ProfileName
    )
    
    if ([string]::IsNullOrWhiteSpace($ProfileName)) {
        $ProfileName = Read-Host "프로필 이름"
    }
    
    Initialize-ProfilesDirectory
    
    $profile = @{
        Name = $ProfileName
        CreatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Tools = @{
            Chocolatey = $true
            Git = $true
            NodeJS = @{ Enabled = $true; Version = "22.12.0" }
            Python = @{ Enabled = $true }
            Java = @{ Enabled = $false }
            Docker = @{ Enabled = $true }
            VSCode = @{ Enabled = $true }
        }
        Databases = @{
            PostgreSQL = $false
            MySQL = $false
            MongoDB = $false
            Redis = $false
        }
    }
    
    # 사용자 입력 받기
    Write-Host ""
    Write-Host "설치할 도구를 선택하세요 (Y/N):" -ForegroundColor Cyan
    Write-Host ""
    
    $profile.Tools.Git = (Read-Host "Git 포함? (Y/N)") -eq 'Y'
    $profile.Tools.NodeJS.Enabled = (Read-Host "Node.js 포함? (Y/N)") -eq 'Y'
    $profile.Tools.Python.Enabled = (Read-Host "Python 포함? (Y/N)") -eq 'Y'
    $profile.Tools.Java.Enabled = (Read-Host "Java 포함? (Y/N)") -eq 'Y'
    $profile.Tools.Docker.Enabled = (Read-Host "Docker 포함? (Y/N)") -eq 'Y'
    $profile.Tools.VSCode.Enabled = (Read-Host "VS Code 포함? (Y/N)") -eq 'Y'
    
    Write-Host ""
    $profile.Databases.PostgreSQL = (Read-Host "PostgreSQL 포함? (Y/N)") -eq 'Y'
    $profile.Databases.MySQL = (Read-Host "MySQL 포함? (Y/N)") -eq 'Y'
    $profile.Databases.MongoDB = (Read-Host "MongoDB 포함? (Y/N)") -eq 'Y'
    $profile.Databases.Redis = (Read-Host "Redis 포함? (Y/N)") -eq 'Y'
    
    $profilePath = Join-Path $ProfilesDir "$ProfileName.json"
    $profile | ConvertTo-Json -Depth 10 | Set-Content -Path $profilePath -Encoding UTF8
    
    Write-Log "프로필 저장 완료: $profilePath" -Level SUCCESS
    return $profilePath
}

function Get-SavedProfiles {
    Initialize-ProfilesDirectory
    
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.json" | Where-Object { $_.Name -notlike "environment_*" }
    return $profiles
}

function Load-InstallProfile {
    param(
        [string]$ProfilePath
    )
    
    if (-not (Test-Path $ProfilePath)) {
        Write-Log "프로필을 찾을 수 없습니다: $ProfilePath" -Level ERROR
        return $null
    }
    
    try {
        $profile = Get-Content -Path $ProfilePath -Raw | ConvertFrom-Json
        Write-Log "프로필 로드 완료: $($profile.Name)" -Level SUCCESS
        return $profile
    } catch {
        Write-Log "프로필 로드 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

# ============================================
# 메뉴
# ============================================

function Show-EnvironmentMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    환경 및 프로필 관리" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 현재 환경 내보내기" -ForegroundColor White
    Write-Host "  [2] 환경 가져오기" -ForegroundColor White
    Write-Host "  [3] 새 프로필 저장" -ForegroundColor White
    Write-Host "  [4] 저장된 프로필 목록" -ForegroundColor White
    Write-Host "  [5] 프로필로 설치" -ForegroundColor White
    Write-Host "  [0] 돌아가기" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Start-EnvironmentManager {
    while ($true) {
        Show-EnvironmentMenu
        $choice = Read-Host "선택"
        
        switch ($choice) {
            "1" { Export-Environment }
            "2" {
                $path = Read-Host "환경 파일 경로"
                Import-Environment -InputPath $path
            }
            "3" { Save-InstallProfile }
            "4" {
                $profiles = Get-SavedProfiles
                Write-Host ""
                Write-Host "저장된 프로필:" -ForegroundColor Cyan
                foreach ($p in $profiles) {
                    Write-Host "  - $($p.BaseName)" -ForegroundColor White
                }
                Write-Host ""
            }
            "5" {
                $profiles = Get-SavedProfiles
                Write-Host ""
                for ($i = 0; $i -lt $profiles.Count; $i++) {
                    Write-Host "  [$($i + 1)] $($profiles[$i].BaseName)" -ForegroundColor White
                }
                Write-Host ""
                $profileChoice = Read-Host "프로필 번호"
                $index = [int]$profileChoice - 1
                if ($index -ge 0 -and $index -lt $profiles.Count) {
                    $profile = Load-InstallProfile -ProfilePath $profiles[$index].FullName
                    if ($profile) {
                        Write-Log "프로필 '$($profile.Name)' 로드됨. 설치를 시작하려면 setup.ps1을 실행하세요." -Level INFO
                    }
                }
            }
            "0" { return }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-EnvironmentManager
}
