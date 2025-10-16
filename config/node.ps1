# ============================================
# Node.js 및 패키지 매니저 설치 (nvm 기반)
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-NVM {
    Write-Log "nvm-windows 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "nvm") {
        $version = nvm version
        Write-Log "nvm이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    # Chocolatey로 nvm-windows 설치
    $result = Install-ChocolateyPackage -PackageName "nvm"

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "nvm-windows 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-NodeJS {
    param(
        [string]$Version = "24.4.0"  # 기본 버전
    )

    Write-Log "Node.js 설치를 시작합니다 (nvm 사용)..." -Level INFO

    # nvm 먼저 설치
    if (-not (Test-ProgramInstalled -CommandCheck "nvm")) {
        Write-Log "nvm을 먼저 설치합니다..." -Level INFO
        $nvmResult = Install-NVM
        if (-not $nvmResult) {
            Write-Log "nvm 설치 실패" -Level ERROR
            return $false
        }
    }

    # Node.js 설치 확인
    if (Test-ProgramInstalled -CommandCheck "node") {
        $currentVersion = node --version
        Write-Log "Node.js가 이미 설치되어 있습니다: $currentVersion" -Level SUCCESS

        # 원하는 버전이 아니면 추가 설치
        if ($currentVersion -notlike "*$Version*") {
            Write-Log "지정된 버전($Version)을 추가로 설치합니다..." -Level INFO
        } else {
            return $true
        }
    }

    try {
        Write-Log "nvm으로 Node.js $Version 설치 중..." -Level INFO

        # Node.js 설치
        nvm install $Version

        if ($LASTEXITCODE -eq 0) {
            # 설치한 버전을 기본으로 사용
            nvm use $Version

            # 환경 변수 새로고침
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            $nodeVersion = node --version
            $npmVersion = npm --version

            Write-Log "Node.js 설치 완료: $nodeVersion" -Level SUCCESS
            Write-Log "npm 버전: $npmVersion" -Level INFO

            # 설치된 Node.js 버전 목록 표시
            Write-Log "설치된 Node.js 버전 목록:" -Level INFO
            nvm list

            return $true
        } else {
            Write-Log "Node.js 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Node.js 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-Yarn {
    Write-Log "Yarn 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "yarn") {
        $version = yarn --version
        Write-Log "Yarn이 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    try {
        npm install -g yarn

        if ($LASTEXITCODE -eq 0) {
            $version = yarn --version
            Write-Log "Yarn 설치 완료: v$version" -Level SUCCESS
            return $true
        } else {
            Write-Log "Yarn 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Yarn 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-Pnpm {
    Write-Log "pnpm 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "pnpm") {
        $version = pnpm --version
        Write-Log "pnpm이 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    try {
        npm install -g pnpm

        if ($LASTEXITCODE -eq 0) {
            $version = pnpm --version
            Write-Log "pnpm 설치 완료: v$version" -Level SUCCESS
            return $true
        } else {
            Write-Log "pnpm 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "pnpm 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-GlobalNpmPackages {
    Write-Log "전역 npm 패키지 설치 중..." -Level INFO

    $packages = @(
        "typescript",
        "ts-node",
        "nodemon",
        "pm2",
        "http-server",
        "live-server"
    )

    $successCount = 0
    $failCount = 0

    foreach ($package in $packages) {
        try {
            Write-Log "설치 중: $package" -Level INFO
            npm install -g $package --silent

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

function Set-NpmConfiguration {
    Write-Log "npm 설정 구성 중..." -Level INFO

    try {
        # 기본 설정
        npm config set init-author-name "Your Name"
        npm config set init-license "MIT"
        npm config set save-exact true

        # 레지스트리 설정 (선택사항)
        # npm config set registry https://registry.npmjs.org/

        Write-Log "npm 설정 완료" -Level SUCCESS
        return $true

    } catch {
        Write-Log "npm 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-NVM
    Install-NodeJS -Version "24.4.0"
    Install-Yarn
    Install-Pnpm
    Install-GlobalNpmPackages
    Set-NpmConfiguration

    # nvm 사용 가이드
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  nvm 사용 가이드" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "다른 Node.js 버전 설치:" -ForegroundColor Yellow
    Write-Host "  nvm install <version>   # 예: nvm install 20.11.0" -ForegroundColor White
    Write-Host ""
    Write-Host "설치된 버전 확인:" -ForegroundColor Yellow
    Write-Host "  nvm list" -ForegroundColor White
    Write-Host ""
    Write-Host "버전 전환:" -ForegroundColor Yellow
    Write-Host "  nvm use <version>       # 예: nvm use 20.11.0" -ForegroundColor White
    Write-Host ""
    Write-Host "현재 사용 중인 버전:" -ForegroundColor Yellow
    Write-Host "  nvm current" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}
