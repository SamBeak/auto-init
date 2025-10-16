# ============================================
# 설치 검증 스크립트
# ============================================

. "$PSScriptRoot\utils.ps1"

$global:ValidationResults = @()

function Add-ValidationResult {
    param(
        [string]$Tool,
        [bool]$IsInstalled,
        [string]$Version = "N/A",
        [string]$Details = ""
    )

    $global:ValidationResults += [PSCustomObject]@{
        Tool = $Tool
        Installed = $IsInstalled
        Version = $Version
        Details = $Details
        Status = if ($IsInstalled) { "✓" } else { "✗" }
    }
}

function Test-PackageManagers {
    Write-Log "패키지 관리자 검증 중..." -Level INFO

    # Chocolatey
    if (Test-ProgramInstalled -CommandCheck "choco") {
        $version = (choco --version)
        Add-ValidationResult -Tool "Chocolatey" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Chocolatey" -IsInstalled $false
    }

    # Winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $version = (winget --version)
        Add-ValidationResult -Tool "Winget" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Winget" -IsInstalled $false
    }
}

function Test-DevelopmentTools {
    Write-Log "개발 도구 검증 중..." -Level INFO

    # Git
    if (Test-ProgramInstalled -CommandCheck "git") {
        $version = (git --version).Replace("git version ", "")
        Add-ValidationResult -Tool "Git" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Git" -IsInstalled $false
    }

    # GitHub CLI
    if (Test-ProgramInstalled -CommandCheck "gh") {
        $version = (gh --version | Select-String "gh version" | Out-String).Trim()
        Add-ValidationResult -Tool "GitHub CLI" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "GitHub CLI" -IsInstalled $false
    }

    # nvm
    if (Test-ProgramInstalled -CommandCheck "nvm") {
        $version = (nvm version)
        Add-ValidationResult -Tool "nvm-windows" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "nvm-windows" -IsInstalled $false
    }

    # Node.js
    if (Test-ProgramInstalled -CommandCheck "node") {
        $version = (node --version)
        Add-ValidationResult -Tool "Node.js" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Node.js" -IsInstalled $false
    }

    # npm
    if (Test-ProgramInstalled -CommandCheck "npm") {
        $version = (npm --version)
        Add-ValidationResult -Tool "npm" -IsInstalled $true -Version "v$version"
    } else {
        Add-ValidationResult -Tool "npm" -IsInstalled $false
    }

    # Yarn
    if (Test-ProgramInstalled -CommandCheck "yarn") {
        $version = (yarn --version)
        Add-ValidationResult -Tool "Yarn" -IsInstalled $true -Version "v$version"
    } else {
        Add-ValidationResult -Tool "Yarn" -IsInstalled $false
    }

    # pnpm
    if (Test-ProgramInstalled -CommandCheck "pnpm") {
        $version = (pnpm --version)
        Add-ValidationResult -Tool "pnpm" -IsInstalled $true -Version "v$version"
    } else {
        Add-ValidationResult -Tool "pnpm" -IsInstalled $false
    }

    # Python
    if (Test-ProgramInstalled -CommandCheck "python") {
        $version = (python --version).Replace("Python ", "")
        Add-ValidationResult -Tool "Python" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Python" -IsInstalled $false
    }

    # pip
    if (Test-ProgramInstalled -CommandCheck "pip") {
        $version = (pip --version | Select-String "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1)
        Add-ValidationResult -Tool "pip" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "pip" -IsInstalled $false
    }

    # Java
    if (Test-ProgramInstalled -CommandCheck "java") {
        $version = (java -version 2>&1 | Select-String "version" | Out-String).Trim()
        Add-ValidationResult -Tool "Java" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Java" -IsInstalled $false
    }

    # Maven
    if (Test-ProgramInstalled -CommandCheck "mvn") {
        $version = (mvn --version | Select-String "Apache Maven" | Out-String).Trim()
        Add-ValidationResult -Tool "Maven" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Maven" -IsInstalled $false
    }

    # Gradle
    if (Test-ProgramInstalled -CommandCheck "gradle") {
        $version = (gradle --version | Select-String "Gradle" | Select-Object -First 1 | Out-String).Trim()
        Add-ValidationResult -Tool "Gradle" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Gradle" -IsInstalled $false
    }

    # Docker
    if (Test-ProgramInstalled -CommandCheck "docker") {
        $version = (docker --version).Replace("Docker version ", "")
        Add-ValidationResult -Tool "Docker" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Docker" -IsInstalled $false
    }

    # VS Code
    if (Test-ProgramInstalled -CommandCheck "code") {
        $version = (code --version | Select-Object -First 1)
        Add-ValidationResult -Tool "Visual Studio Code" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Visual Studio Code" -IsInstalled $false
    }
}

function Test-Databases {
    Write-Log "데이터베이스 검증 중..." -Level INFO

    # PostgreSQL
    if (Test-ProgramInstalled -CommandCheck "psql") {
        $version = (psql --version).Replace("psql (PostgreSQL) ", "")
        Add-ValidationResult -Tool "PostgreSQL" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "PostgreSQL" -IsInstalled $false
    }

    # MySQL
    if (Test-ProgramInstalled -CommandCheck "mysql") {
        $version = (mysql --version | Select-String "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1)
        Add-ValidationResult -Tool "MySQL" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "MySQL" -IsInstalled $false
    }

    # MongoDB
    if (Test-ProgramInstalled -CommandCheck "mongod") {
        $version = (mongod --version | Select-String "db version" | Out-String).Trim()
        Add-ValidationResult -Tool "MongoDB" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "MongoDB" -IsInstalled $false
    }

    # Redis
    if (Test-ProgramInstalled -CommandCheck "redis-server") {
        Add-ValidationResult -Tool "Redis" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "Redis" -IsInstalled $false
    }
}

function Test-AdditionalTools {
    Write-Log "추가 도구 검증 중..." -Level INFO

    # 전자정부프레임워크
    $egovPath = "C:\eGovFrameDev-3.10.0"
    if (Test-Path $egovPath) {
        Add-ValidationResult -Tool "전자정부프레임워크" -IsInstalled $true -Version "3.10.0" -Details $egovPath
    } else {
        Add-ValidationResult -Tool "전자정부프레임워크" -IsInstalled $false
    }

    # Prettier
    if (Test-ProgramInstalled -CommandCheck "prettier") {
        $version = (prettier --version)
        Add-ValidationResult -Tool "Prettier" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Prettier" -IsInstalled $false
    }

    # ESLint
    if (Test-ProgramInstalled -CommandCheck "eslint") {
        $version = (eslint --version).Replace("v", "")
        Add-ValidationResult -Tool "ESLint" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "ESLint" -IsInstalled $false
    }

    # Oh My Posh
    if (Test-ProgramInstalled -CommandCheck "oh-my-posh") {
        $version = (oh-my-posh --version)
        Add-ValidationResult -Tool "Oh My Posh" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "Oh My Posh" -IsInstalled $false
    }

    # Postman
    if (Test-ProgramInstalled -ProgramName "Postman") {
        Add-ValidationResult -Tool "Postman" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "Postman" -IsInstalled $false
    }

    # HeidiSQL
    if (Test-ProgramInstalled -ProgramName "HeidiSQL") {
        Add-ValidationResult -Tool "HeidiSQL" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "HeidiSQL" -IsInstalled $false
    }

    # Notepad++
    if (Test-ProgramInstalled -ProgramName "Notepad++") {
        Add-ValidationResult -Tool "Notepad++" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "Notepad++" -IsInstalled $false
    }

    # Figma
    if (Test-ProgramInstalled -ProgramName "Figma") {
        Add-ValidationResult -Tool "Figma" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "Figma" -IsInstalled $false
    }

    # PowerShell 7
    if (Test-ProgramInstalled -CommandCheck "pwsh") {
        $version = (pwsh --version).Replace("PowerShell ", "")
        Add-ValidationResult -Tool "PowerShell 7" -IsInstalled $true -Version $version
    } else {
        Add-ValidationResult -Tool "PowerShell 7" -IsInstalled $false
    }

    # Windows Terminal
    if (Test-ProgramInstalled -ProgramName "Windows Terminal") {
        Add-ValidationResult -Tool "Windows Terminal" -IsInstalled $true
    } else {
        Add-ValidationResult -Tool "Windows Terminal" -IsInstalled $false
    }
}

function Show-ValidationReport {
    Write-Log "`n========================================" -Level INFO
    Write-Log "설치 검증 보고서" -Level INFO
    Write-Log "========================================`n" -Level INFO

    # 테이블 형식으로 출력
    $global:ValidationResults | Format-Table -Property Status, Tool, Installed, Version -AutoSize | Out-String | Write-Host

    # 통계
    $totalTools = $global:ValidationResults.Count
    $installedTools = ($global:ValidationResults | Where-Object { $_.Installed -eq $true }).Count
    $missingTools = $totalTools - $installedTools

    Write-Log "`n========================================" -Level INFO
    Write-Log "총 도구: $totalTools" -Level INFO
    Write-Log "설치됨: $installedTools" -Level SUCCESS
    Write-Log "미설치: $missingTools" -Level $(if ($missingTools -eq 0) { "SUCCESS" } else { "WARNING" })
    Write-Log "========================================`n" -Level INFO

    # 미설치 도구 목록
    if ($missingTools -gt 0) {
        Write-Log "미설치 도구 목록:" -Level WARNING
        $global:ValidationResults | Where-Object { $_.Installed -eq $false } | ForEach-Object {
            Write-Log "  - $($_.Tool)" -Level WARNING
        }
    }

    # 보고서 파일 저장
    $reportPath = Join-Path $PSScriptRoot "..\logs\validation_report.txt"
    $global:ValidationResults | Format-Table -Property Status, Tool, Installed, Version -AutoSize | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "`n검증 보고서 저장: $reportPath" -Level INFO
}

# 메인 실행
function Start-Validation {
    Write-Log "설치 검증을 시작합니다..." -Level INFO

    $global:ValidationResults = @()

    Test-PackageManagers
    Test-DevelopmentTools
    Test-Databases
    Test-AdditionalTools

    Show-ValidationReport
}

# 직접 실행 시
if ($MyInvocation.InvocationName -ne '.') {
    Start-Validation
}
