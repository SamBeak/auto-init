# ============================================
# Windows 풀스택 개발 환경 자동 설치 시스템
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

# 스크립트 경로
$ScriptRoot = $PSScriptRoot

# 유틸리티 로드
. "$ScriptRoot\scripts\utils.ps1"

# 배너 출력
Show-Banner

# 관리자 권한 확인
Require-Administrator

# 사전 요구사항 체크
$prerequisitesOk = Test-Prerequisites

if (-not $prerequisitesOk) {
    Write-Host ""
    $continue = Read-Host "일부 요구사항이 충족되지 않았습니다. 계속 진행하시겠습니까? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        Write-Log "사용자가 설치를 취소했습니다." -Level INFO
        exit 0
    }
    Write-Log "사용자가 계속 진행을 선택했습니다." -Level WARNING
}

# ============================================
# 메뉴 함수
# ============================================

function Show-MainMenu {
    Write-Host "`n" -NoNewline
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    메인 메뉴                                  ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  설치 모드                                                    ║" -ForegroundColor Cyan
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  [1] 빠른 설치 (풀스택 개발자)    [2] 프론트엔드 개발자       ║" -ForegroundColor White
    Write-Host "║  [3] 백엔드 개발자                [4] 데이터 엔지니어         ║" -ForegroundColor White
    Write-Host "║  [5] 사용자 정의 선택             [6] 버전 선택 후 설치       ║" -ForegroundColor White
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  도구                                                         ║" -ForegroundColor Yellow
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  [7] 설치 검증                    [8] 헬스 체크               ║" -ForegroundColor Yellow
    Write-Host "║  [9] 도구 업데이트                [A] 프로젝트 템플릿 생성    ║" -ForegroundColor Yellow
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  고급 기능                                                    ║" -ForegroundColor Magenta
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  [B] 오프라인 설치 모드           [C] 오프라인 캐시 다운로드  ║" -ForegroundColor Magenta
    Write-Host "║  [D] 환경 내보내기/가져오기       [E] 무인 설치 (config.json) ║" -ForegroundColor Magenta
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  테스트 모드                                                  ║" -ForegroundColor Green
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  [F] DRY-RUN 모드 (시뮬레이션)     [G] 개별 스크립트 테스트    ║" -ForegroundColor Green
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  [0] 종료                                                     ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-UserChoice {
    $choice = Read-Host "선택"
    return $choice.ToUpper()
}

# ============================================
# 테스트 모드 함수들
# ============================================

function Test-IndividualScripts {
    Write-Host "`n테스트할 스크립트를 선택하세요:`n" -ForegroundColor Cyan
    
    $scripts = @{
        "1" = @{ Name = "Chocolatey"; Path = "$ScriptRoot\config\chocolatey.ps1" }
        "2" = @{ Name = "Git"; Path = "$ScriptRoot\config\git.ps1" }
        "3" = @{ Name = "Node.js"; Path = "$ScriptRoot\config\node.ps1" }
        "4" = @{ Name = "Python"; Path = "$ScriptRoot\config\python.ps1" }
        "5" = @{ Name = "Java"; Path = "$ScriptRoot\config\java.ps1" }
        "6" = @{ Name = "Docker"; Path = "$ScriptRoot\config\docker.ps1" }
        "7" = @{ Name = "VS Code"; Path = "$ScriptRoot\config\vscode.ps1" }
        "8" = @{ Name = "추가 도구"; Path = "$ScriptRoot\config\tools.ps1" }
        "9" = @{ Name = "린터"; Path = "$ScriptRoot\config\linters.ps1" }
        "0" = @{ Name = "취소"; Path = $null }
    }
    
    foreach ($key in $scripts.Keys | Sort-Object) {
        if ($scripts[$key].Name -ne "취소") {
            Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor White
        } else {
            Write-Host "  [$key] $($scripts[$key].Name)" -ForegroundColor Red
        }
    }
    
    $choice = Read-Host "`n선택"
    if ($choice -eq "0") { return }
    
    if ($scripts.ContainsKey($choice)) {
        $script = $scripts[$choice]
        Write-Host "`n$($script.Name) 스크립트를 테스트합니다..." -ForegroundColor Yellow
        
        try {
            # Syntax check only
            $errors = $null
            [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.Path -Raw), [ref]$errors)
            
            if ($errors.Count -eq 0) {
                Write-Host "✅ Syntax 검사 통과" -ForegroundColor Green
            } else {
                Write-Host "❌ Syntax 오류 발견:" -ForegroundColor Red
                $errors | ForEach-Object { Write-Host "  $($_.Message)" -ForegroundColor Red }
            }
            
            # Function existence check
            $content = Get-Content $script.Path -Raw
            $functions = [regex]::Matches($content, 'function\s+(\w+)')
            Write-Host "`n함수 목록:" -ForegroundColor Cyan
            $functions | ForEach-Object { Write-Host "  - $($_.Groups[1].Value)" -ForegroundColor White }
            
        } catch {
            Write-Host "❌ 스크립트 로드 실패: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "잘못된 선택입니다." -ForegroundColor Red
    }
    
    Read-Host "`n계속하려면 Enter를 누르세요"
}

function Start-DryRun {
    Write-Host "`n🔍 DRY-RUN 모드: 실제 설치는 하지 않고 시뮬레이션만 합니다.`n" -ForegroundColor Yellow
    
    $selectedProfile = Read-Host "테스트할 프로필을 선택하세요 (1: 풀스택, 2: 프론트엔드, 3: 백엔드, 4: 데이터엔지니어)"
    
    switch ($selectedProfile) {
        "1" { $profileName = "풀스택 개발자" }
        "2" { $profileName = "프론트엔드 개발자" }
        "3" { $profileName = "백엔드 개발자" }
        "4" { $profileName = "데이터 엔지니어" }
        default { Write-Host "잘못된 선택입니다."; return }
    }
    
    Write-Host "`n📋 $profileName 프로필 설치 시뮬레이션:`n" -ForegroundColor Cyan
    
    $steps = @(
        "Chocolatey 패키지 관리자 설치",
        "Git 및 GitHub CLI 설치",
        "Node.js 및 npm/yarn/pnpm 설치",
        "Python 및 pip/poetry 설치",
        "Java (OpenJDK) 및 Maven/Gradle 설치",
        "Docker Desktop 설치",
        "Visual Studio Code 및 확장 설치",
        "데이터베이스 (PostgreSQL, MySQL, MongoDB, Redis) 설치",
        "추가 도구 (Postman, HeidiSQL 등) 설치",
        "코드 품질 도구 (Prettier, ESLint) 설치"
    )
    
    $totalSteps = $steps.Count
    for ($i = 0; $i -lt $totalSteps; $i++) {
        $stepNum = $i + 1
        $percent = [math]::Round(($stepNum / $totalSteps) * 100)
        
        Write-Host "[$stepNum/$totalSteps] $($steps[$i])" -NoNewline -ForegroundColor White
        Start-Sleep -Milliseconds 500
        Write-Host " ... " -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 300
        Write-Host "✅ SIMULATED" -ForegroundColor Green
        
        # 진행률 바 표시
        $barWidth = 30
        $filled = [math]::Round($barWidth * $percent / 100)
        $empty = $barWidth - $filled
        Write-Host "  [" -NoNewline -ForegroundColor Gray
        Write-Host ("█" * $filled) -NoNewline -ForegroundColor Green
        Write-Host ("░" * $empty) -NoNewline -ForegroundColor DarkGray
        Write-Host "] $percent%" -ForegroundColor Yellow
    }
    
    Write-Host "`n🎉 시뮬레이션 완료! 실제 설치는 하지 않았습니다." -ForegroundColor Green
    Write-Host "💡 실제 설치를 하려면 메뉴에서 해당 프로필을 선택하세요." -ForegroundColor Cyan
    
    Read-Host "`n계속하려면 Enter를 누르세요"
}

# ============================================
# 데이터베이스 설정 입력 함수
# ============================================

function Get-DatabaseConfiguration {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  데이터베이스 설정" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "각 데이터베이스의 설정을 입력하세요." -ForegroundColor Yellow
    Write-Host "(Enter키를 누르면 기본값이 사용됩니다)" -ForegroundColor Yellow
    Write-Host ""

    $dbConfig = @{}

    # PostgreSQL 설정
    Write-Host "=== PostgreSQL 설정 ===" -ForegroundColor Green
    $dbConfig.PostgreSQL = @{
        Port = Read-Host "포트 번호 (기본: 5432)"
        Username = Read-Host "사용자 이름 (기본: postgres)"
        Password = Read-Host "비밀번호 (기본: postgres)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.PostgreSQL.Port)) { $dbConfig.PostgreSQL.Port = "5432" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.PostgreSQL.Username)) { $dbConfig.PostgreSQL.Username = "postgres" }
    $pgPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.PostgreSQL.Password))
    if ([string]::IsNullOrWhiteSpace($pgPassPlain)) { $pgPassPlain = "postgres" }
    $dbConfig.PostgreSQL.Password = $pgPassPlain
    Write-Host ""

    # MySQL 설정
    Write-Host "=== MySQL 설정 ===" -ForegroundColor Green
    $dbConfig.MySQL = @{
        Port = Read-Host "포트 번호 (기본: 3306)"
        Username = Read-Host "Root 사용자 (기본: root)"
        Password = Read-Host "Root 비밀번호 (기본: root)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MySQL.Port)) { $dbConfig.MySQL.Port = "3306" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MySQL.Username)) { $dbConfig.MySQL.Username = "root" }
    $mysqlPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.MySQL.Password))
    if ([string]::IsNullOrWhiteSpace($mysqlPassPlain)) { $mysqlPassPlain = "root" }
    $dbConfig.MySQL.Password = $mysqlPassPlain
    Write-Host ""

    # MongoDB 설정
    Write-Host "=== MongoDB 설정 ===" -ForegroundColor Green
    $dbConfig.MongoDB = @{
        Port = Read-Host "포트 번호 (기본: 27017)"
        Username = Read-Host "관리자 사용자 (기본: admin)"
        Password = Read-Host "관리자 비밀번호 (기본: admin)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MongoDB.Port)) { $dbConfig.MongoDB.Port = "27017" }
    if ([string]::IsNullOrWhiteSpace($dbConfig.MongoDB.Username)) { $dbConfig.MongoDB.Username = "admin" }
    $mongoPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.MongoDB.Password))
    if ([string]::IsNullOrWhiteSpace($mongoPassPlain)) { $mongoPassPlain = "admin" }
    $dbConfig.MongoDB.Password = $mongoPassPlain
    Write-Host ""

    # Redis 설정
    Write-Host "=== Redis 설정 ===" -ForegroundColor Green
    $dbConfig.Redis = @{
        Port = Read-Host "포트 번호 (기본: 6379)"
        Password = Read-Host "비밀번호 (선택, Enter로 건너뛰기)" -AsSecureString
    }
    if ([string]::IsNullOrWhiteSpace($dbConfig.Redis.Port)) { $dbConfig.Redis.Port = "6379" }
    $redisPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbConfig.Redis.Password))
    $dbConfig.Redis.Password = $redisPassPlain
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    return $dbConfig
}

# ============================================
# 진행률 표시 함수
# ============================================

$global:TotalSteps = 0
$global:CurrentStep = 0
$global:InstallStartTime = $null

function Initialize-Progress {
    param([int]$Steps)
    $global:TotalSteps = $Steps
    $global:CurrentStep = 0
    $global:InstallStartTime = Get-Date
}

function Update-InstallProgress {
    param([string]$StepName)
    
    $global:CurrentStep++
    $percent = [math]::Round(($global:CurrentStep / $global:TotalSteps) * 100)
    
    # 경과 시간 계산
    $elapsed = (Get-Date) - $global:InstallStartTime
    $elapsedStr = $elapsed.ToString('mm\:ss')
    
    # 예상 남은 시간 계산
    if ($global:CurrentStep -gt 0) {
        $avgTimePerStep = $elapsed.TotalSeconds / $global:CurrentStep
        $remainingSteps = $global:TotalSteps - $global:CurrentStep
        $remainingSeconds = $avgTimePerStep * $remainingSteps
        $remainingStr = [TimeSpan]::FromSeconds($remainingSeconds).ToString('mm\:ss')
    } else {
        $remainingStr = "--:--"
    }
    
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "[$global:CurrentStep/$global:TotalSteps] $StepName" -ForegroundColor White -NoNewline
    Write-Host (" " * (47 - $StepName.Length - 6)) -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    
    # 진행률 바
    $barWidth = 30
    $filled = [math]::Round($barWidth * $percent / 100)
    $empty = $barWidth - $filled
    Write-Host "[" -NoNewline -ForegroundColor Gray
    Write-Host ("█" * $filled) -NoNewline -ForegroundColor Green
    Write-Host ("░" * $empty) -NoNewline -ForegroundColor DarkGray
    Write-Host "] " -NoNewline -ForegroundColor Gray
    Write-Host "$percent%" -NoNewline -ForegroundColor Yellow
    Write-Host "        │" -ForegroundColor DarkCyan
    
    Write-Host "│ " -ForegroundColor DarkCyan -NoNewline
    Write-Host "경과: $elapsedStr | 예상 남은 시간: $remainingStr" -ForegroundColor Gray -NoNewline
    Write-Host "          │" -ForegroundColor DarkCyan
    Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
    
    Write-Progress -Activity "개발 환경 설치" -Status "$StepName ($percent%)" -PercentComplete $percent
}

# ============================================
# 설치 프로파일 정의
# ============================================

$global:InstallProfiles = @{
    "FullStack" = @{
        Name = "풀스택 개발자"
        Description = "웹 프론트엔드, 백엔드, 데이터베이스를 포함한 전체 개발 환경"
        Categories = @(
            @{
                Name = "패키지 관리자"
                Items = @("Chocolatey", "Winget")
            },
            @{
                Name = "버전 관리"
                Items = @("Git", "GitHub CLI")
            },
            @{
                Name = "런타임 & 언어"
                Items = @("Node.js (NVM)", "npm/yarn/pnpm", "Python", "pip/poetry", "Java (OpenJDK)", "Maven/Gradle")
            },
            @{
                Name = "컨테이너"
                Items = @("Docker Desktop")
            },
            @{
                Name = "IDE & 에디터"
                Items = @("Visual Studio Code", "VS Code 확장 프로그램")
            },
            @{
                Name = "프레임워크"
                Items = @("전자정부프레임워크 3.10")
            },
            @{
                Name = "데이터베이스"
                Items = @("PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite Studio")
            },
            @{
                Name = "개발 도구"
                Items = @("Postman", "HeidiSQL", "Oh My Posh", "ngrok")
            },
            @{
                Name = "DevOps & 클라우드"
                Items = @("kubectl")
            },
            @{
                Name = "코드 품질"
                Items = @("Prettier", "ESLint")
            }
        )
    }
    "Frontend" = @{
        Name = "프론트엔드 개발자"
        Description = "웹 프론트엔드 개발에 필요한 환경"
        Categories = @(
            @{
                Name = "패키지 관리자"
                Items = @("Chocolatey")
            },
            @{
                Name = "버전 관리"
                Items = @("Git", "GitHub CLI")
            },
            @{
                Name = "런타임 & 언어"
                Items = @("Node.js (NVM)", "npm/yarn/pnpm")
            },
            @{
                Name = "IDE & 에디터"
                Items = @("Visual Studio Code", "VS Code 확장 프로그램")
            },
            @{
                Name = "개발 도구"
                Items = @("Postman", "Oh My Posh", "ngrok")
            },
            @{
                Name = "코드 품질"
                Items = @("Prettier", "ESLint")
            }
        )
    }
    "Backend" = @{
        Name = "백엔드 개발자"
        Description = "서버 개발 및 데이터베이스 환경"
        Categories = @(
            @{
                Name = "패키지 관리자"
                Items = @("Chocolatey")
            },
            @{
                Name = "버전 관리"
                Items = @("Git", "GitHub CLI")
            },
            @{
                Name = "런타임 & 언어"
                Items = @("Node.js (NVM)", "npm/yarn/pnpm", "Python", "pip/poetry", "Java (OpenJDK)", "Maven/Gradle")
            },
            @{
                Name = "컨테이너"
                Items = @("Docker Desktop")
            },
            @{
                Name = "IDE & 에디터"
                Items = @("Visual Studio Code", "VS Code 확장 프로그램")
            },
            @{
                Name = "데이터베이스"
                Items = @("PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite Studio")
            },
            @{
                Name = "개발 도구"
                Items = @("Postman", "HeidiSQL", "ngrok")
            },
            @{
                Name = "DevOps & 클라우드"
                Items = @("kubectl")
            }
        )
    }
    "DataEngineer" = @{
        Name = "데이터 엔지니어"
        Description = "데이터 처리 및 분석 환경"
        Categories = @(
            @{
                Name = "패키지 관리자"
                Items = @("Chocolatey")
            },
            @{
                Name = "버전 관리"
                Items = @("Git", "GitHub CLI")
            },
            @{
                Name = "런타임 & 언어"
                Items = @("Python", "pip/poetry", "Jupyter Notebook")
            },
            @{
                Name = "컨테이너"
                Items = @("Docker Desktop")
            },
            @{
                Name = "IDE & 에디터"
                Items = @("Visual Studio Code", "VS Code 확장 프로그램")
            },
            @{
                Name = "데이터베이스"
                Items = @("PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite Studio")
            },
            @{
                Name = "빅데이터 도구"
                Items = @("Apache Spark")
            },
            @{
                Name = "DevOps & 클라우드"
                Items = @("kubectl")
            }
        )
    }
}

function Show-ProfileDetails {
    param(
        [string]$ProfileKey
    )
    
    $profile = $global:InstallProfiles[$ProfileKey]
    if (-not $profile) {
        Write-Host "프로필을 찾을 수 없습니다." -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "$($profile.Name)" -ForegroundColor Yellow -NoNewline
    Write-Host " 설치 항목" -ForegroundColor White -NoNewline
    $padding = 47 - $profile.Name.Length
    Write-Host (" " * $padding) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "$($profile.Description)" -ForegroundColor Gray -NoNewline
    $descPadding = 60 - $profile.Description.Length
    if ($descPadding -lt 0) { $descPadding = 0 }
    Write-Host (" " * $descPadding) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    
    $totalItems = 0
    foreach ($category in $profile.Categories) {
        Write-Host "║  " -ForegroundColor Cyan -NoNewline
        Write-Host "📦 $($category.Name)" -ForegroundColor Green -NoNewline
        $catPadding = 57 - $category.Name.Length
        Write-Host (" " * $catPadding) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
        
        foreach ($item in $category.Items) {
            Write-Host "║     " -ForegroundColor Cyan -NoNewline
            Write-Host "• $item" -ForegroundColor White -NoNewline
            $itemPadding = 56 - $item.Length
            Write-Host (" " * $itemPadding) -NoNewline
            Write-Host "║" -ForegroundColor Cyan
            $totalItems++
        }
        Write-Host "║" -ForegroundColor Cyan
    }
    
    Write-Host "╟───────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "총 $totalItems 개 항목이 설치됩니다" -ForegroundColor Yellow -NoNewline
    Write-Host "                                      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    return Confirm-Action "이 항목들을 설치하시겠습니까?" -DefaultYes $true
}

# ============================================
# 설치 프로파일 함수
# ============================================

function Install-FullStack {
    Write-Log "풀스택 개발 환경 설치를 시작합니다..." -Level INFO
    
    Initialize-Progress -Steps 12

    # 패키지 관리자
    Update-InstallProgress -StepName "Chocolatey 설치"
    & "$ScriptRoot\config\chocolatey.ps1"
    
    Update-InstallProgress -StepName "Winget 설치"
    & "$ScriptRoot\config\winget.ps1"

    # 핵심 도구
    Update-InstallProgress -StepName "Git 설치"
    & "$ScriptRoot\config\git.ps1"
    
    Update-InstallProgress -StepName "Node.js 설치"
    & "$ScriptRoot\config\node.ps1"
    
    Update-InstallProgress -StepName "Python 설치"
    & "$ScriptRoot\config\python.ps1"
    
    Update-InstallProgress -StepName "Java 설치"
    & "$ScriptRoot\config\java.ps1"
    
    Update-InstallProgress -StepName "Docker 설치"
    & "$ScriptRoot\config\docker.ps1"
    
    Update-InstallProgress -StepName "VS Code 설치"
    & "$ScriptRoot\config\vscode.ps1"

    # 전자정부프레임워크
    Update-InstallProgress -StepName "전자정부프레임워크 설치"
    & "$ScriptRoot\config\egovframework.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    Update-InstallProgress -StepName "데이터베이스 설치"
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    Update-InstallProgress -StepName "추가 도구 설치"
    & "$ScriptRoot\config\tools.ps1"
    
    Update-InstallProgress -StepName "코드 품질 도구 설치"
    & "$ScriptRoot\config\linters.ps1"

    Write-Progress -Activity "개발 환경 설치" -Completed
    Write-Log "풀스택 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-Frontend {
    Write-Log "프론트엔드 개발 환경 설치를 시작합니다..." -Level INFO

    Initialize-Progress -Steps 6

    # 패키지 관리자
    Update-InstallProgress -StepName "Chocolatey 설치"
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    Update-InstallProgress -StepName "Git 설치"
    & "$ScriptRoot\config\git.ps1"
    
    Update-InstallProgress -StepName "Node.js 설치"
    & "$ScriptRoot\config\node.ps1"
    
    Update-InstallProgress -StepName "VS Code 설치"
    & "$ScriptRoot\config\vscode.ps1"

    # 추가 도구
    Update-InstallProgress -StepName "추가 도구 설치"
    & "$ScriptRoot\config\tools.ps1"
    
    Update-InstallProgress -StepName "코드 품질 도구 설치"
    & "$ScriptRoot\config\linters.ps1"

    Write-Progress -Activity "개발 환경 설치" -Completed
    Write-Log "프론트엔드 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-Backend {
    Write-Log "백엔드 개발 환경 설치를 시작합니다..." -Level INFO

    Initialize-Progress -Steps 9

    # 패키지 관리자
    Update-InstallProgress -StepName "Chocolatey 설치"
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    Update-InstallProgress -StepName "Git 설치"
    & "$ScriptRoot\config\git.ps1"
    
    Update-InstallProgress -StepName "Node.js 설치"
    & "$ScriptRoot\config\node.ps1"
    
    Update-InstallProgress -StepName "Python 설치"
    & "$ScriptRoot\config\python.ps1"
    
    Update-InstallProgress -StepName "Java 설치"
    & "$ScriptRoot\config\java.ps1"
    
    Update-InstallProgress -StepName "Docker 설치"
    & "$ScriptRoot\config\docker.ps1"
    
    Update-InstallProgress -StepName "VS Code 설치"
    & "$ScriptRoot\config\vscode.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    Update-InstallProgress -StepName "데이터베이스 설치"
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    Update-InstallProgress -StepName "추가 도구 설치"
    & "$ScriptRoot\config\tools.ps1"

    Write-Progress -Activity "개발 환경 설치" -Completed
    Write-Log "백엔드 개발 환경 설치 완료!" -Level SUCCESS
}

function Install-DataEngineer {
    Write-Log "데이터 엔지니어 환경 설치를 시작합니다..." -Level INFO

    Initialize-Progress -Steps 7

    # 패키지 관리자
    Update-InstallProgress -StepName "Chocolatey 설치"
    & "$ScriptRoot\config\chocolatey.ps1"

    # 기본 도구
    Update-InstallProgress -StepName "Git 설치"
    & "$ScriptRoot\config\git.ps1"
    
    Update-InstallProgress -StepName "Python 설치"
    & "$ScriptRoot\config\python.ps1"
    
    Update-InstallProgress -StepName "Docker 설치"
    & "$ScriptRoot\config\docker.ps1"
    
    Update-InstallProgress -StepName "VS Code 설치"
    & "$ScriptRoot\config\vscode.ps1"

    # 데이터베이스 설정 입력
    $dbConfig = Get-DatabaseConfiguration

    # 데이터베이스 설치
    Update-InstallProgress -StepName "데이터베이스 설치"
    . "$ScriptRoot\config\database.ps1"
    Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
    Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
    Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
    Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart

    # 추가 도구
    Update-InstallProgress -StepName "Apache Spark 설치"
    . "$ScriptRoot\config\chocolatey.ps1"
    Install-ChocolateyPackage -PackageName "apache-spark"

    Write-Progress -Activity "개발 환경 설치" -Completed
    Write-Log "데이터 엔지니어 환경 설치 완료!" -Level SUCCESS
}

function Install-Custom {
    Write-Log "사용자 정의 설치를 시작합니다..." -Level INFO

    Write-Host "`n설치할 도구를 선택하세요 (Y/N):`n" -ForegroundColor Cyan

    # 패키지 관리자
    if (Confirm-Action "Chocolatey 패키지 관리자 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\chocolatey.ps1"
    }

    # Git
    if (Confirm-Action "Git 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\git.ps1"
    }

    # Node.js
    if (Confirm-Action "Node.js 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\node.ps1"
    }

    # Python
    if (Confirm-Action "Python 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\python.ps1"
    }

    # Java
    if (Confirm-Action "Java 설치?" -DefaultYes $false) {
        & "$ScriptRoot\config\java.ps1"
    }

    # Docker
    if (Confirm-Action "Docker Desktop 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\docker.ps1"
    }

    # VS Code
    if (Confirm-Action "Visual Studio Code 설치?" -DefaultYes $true) {
        & "$ScriptRoot\config\vscode.ps1"
    }

    # 데이터베이스
    if (Confirm-Action "데이터베이스 설치 (PostgreSQL, MySQL, MongoDB, Redis)?" -DefaultYes $true) {
        # 데이터베이스 설정 입력
        $dbConfig = Get-DatabaseConfiguration

        # 데이터베이스 설치
        . "$ScriptRoot\config\database.ps1"
        Install-PostgreSQL -Port $dbConfig.PostgreSQL.Port -Username $dbConfig.PostgreSQL.Username -Password $dbConfig.PostgreSQL.Password
        Install-MySQL -Port $dbConfig.MySQL.Port -Username $dbConfig.MySQL.Username -Password $dbConfig.MySQL.Password
        Install-MongoDB -Port $dbConfig.MongoDB.Port -Username $dbConfig.MongoDB.Username -Password $dbConfig.MongoDB.Password
        Install-Redis -Port $dbConfig.Redis.Port -Password $dbConfig.Redis.Password
        Install-SQLiteStudio
        Start-DatabaseServices
        Set-DatabaseAutoStart
    }

    # 추가 도구
    if (Confirm-Action "추가 도구 설치 (Postman, HeidiSQL, Oh My Posh 등)?" -DefaultYes $true) {
        & "$ScriptRoot\config\tools.ps1"
    }

    # 린터
    if (Confirm-Action "코드 품질 도구 설치 (Prettier, ESLint)?" -DefaultYes $true) {
        & "$ScriptRoot\config\linters.ps1"
    }

    # 전자정부프레임워크
    if (Confirm-Action "전자정부프레임워크 3.10 설치?" -DefaultYes $false) {
        & "$ScriptRoot\config\egovframework.ps1"
    }

    Write-Log "사용자 정의 설치 완료!" -Level SUCCESS
}

# ============================================
# 메인 로직
# ============================================

function Start-Installation {
    $startTime = Get-Date
    
    # 설치 결과 초기화
    Initialize-InstallResults

    while ($true) {
        Show-MainMenu
        $choice = Get-UserChoice

        switch ($choice) {
            "1" {
                Write-Log "풀스택 개발자 모드 선택" -Level INFO
                if (Show-ProfileDetails -ProfileKey "FullStack") {
                    Install-FullStack
                } else {
                    Write-Log "설치가 취소되었습니다." -Level INFO
                    continue
                }
                break
            }
            "2" {
                Write-Log "프론트엔드 개발자 모드 선택" -Level INFO
                if (Show-ProfileDetails -ProfileKey "Frontend") {
                    Install-Frontend
                } else {
                    Write-Log "설치가 취소되었습니다." -Level INFO
                    continue
                }
                break
            }
            "3" {
                Write-Log "백엔드 개발자 모드 선택" -Level INFO
                if (Show-ProfileDetails -ProfileKey "Backend") {
                    Install-Backend
                } else {
                    Write-Log "설치가 취소되었습니다." -Level INFO
                    continue
                }
                break
            }
            "4" {
                Write-Log "데이터 엔지니어 모드 선택" -Level INFO
                if (Show-ProfileDetails -ProfileKey "DataEngineer") {
                    Install-DataEngineer
                } else {
                    Write-Log "설치가 취소되었습니다." -Level INFO
                    continue
                }
                break
            }
            "5" {
                Write-Log "사용자 정의 모드 선택" -Level INFO
                Install-Custom
                break
            }
            "6" {
                Write-Log "버전 선택 모드 실행" -Level INFO
                . "$ScriptRoot\scripts\version-selector.ps1"
                $versions = Start-VersionSelection
                if ($versions.NodeJS) {
                    . "$ScriptRoot\config\node.ps1"
                    Install-NVM
                    Install-NodeJS -Version $versions.NodeJS
                }
                continue
            }
            "7" {
                Write-Log "설치 검증 실행" -Level INFO
                & "$ScriptRoot\scripts\validator.ps1"
                continue
            }
            "8" {
                Write-Log "헬스 체크 실행" -Level INFO
                & "$ScriptRoot\scripts\health-check.ps1"
                continue
            }
            "9" {
                Write-Log "도구 업데이트 실행" -Level INFO
                & "$ScriptRoot\scripts\update-tools.ps1"
                continue
            }
            "A" {
                Write-Log "프로젝트 템플릿 생성기 실행" -Level INFO
                & "$ScriptRoot\scripts\project-template.ps1"
                continue
            }
            "B" {
                Write-Log "오프라인 설치 모드 실행" -Level INFO
                & "$ScriptRoot\scripts\offline-install.ps1"
                continue
            }
            "C" {
                Write-Log "오프라인 캐시 다운로드 실행" -Level INFO
                & "$ScriptRoot\scripts\cache-manager.ps1"
                continue
            }
            "D" {
                Write-Log "환경 관리 실행" -Level INFO
                & "$ScriptRoot\scripts\environment-manager.ps1"
                continue
            }
            "E" {
                Write-Log "무인 설치 모드 실행" -Level INFO
                & "$ScriptRoot\scripts\unattended-install.ps1"
                continue
            }
            "F" {
                Write-Log "DRY-RUN 모드 실행" -Level INFO
                Start-DryRun
                continue
            }
            "G" {
                Write-Log "개별 스크립트 테스트 실행" -Level INFO
                Test-IndividualScripts
                continue
            }
            "0" {
                Write-Log "설치를 종료합니다." -Level INFO
                exit 0
            }
            default {
                Write-Log "잘못된 선택입니다. 다시 선택해주세요." -Level WARNING
                continue
            }
        }

        break
    }

    # 설치 결과 요약 표시
    Show-InstallSummary

    # 설치 후 검증
    Write-Host "`n" -NoNewline
    if (Confirm-Action "설치 검증을 실행하시겠습니까?" -DefaultYes $true) {
        & "$ScriptRoot\scripts\validator.ps1"
    }

    # 완료 메시지
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  설치가 완료되었습니다!" -ForegroundColor Green
    Write-Host "  소요 시간: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    # 재시작 권장
    if (Confirm-Action "시스템을 재시작하시겠습니까?" -DefaultYes $false) {
        Write-Log "시스템을 재시작합니다..." -Level INFO
        Restart-Computer -Force
    } else {
        Write-Log "일부 변경사항을 적용하려면 시스템 재시작이 필요할 수 있습니다." -Level WARNING
    }
}

# 스크립트 실행
try {
    Start-Installation
} catch {
    Write-Log "치명적인 오류가 발생했습니다: $($_.Exception.Message)" -Level ERROR
    Write-Log "스택 트레이스: $($_.ScriptStackTrace)" -Level ERROR
    exit 1
}
