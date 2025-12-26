# ============================================
# Windows 개발 환경 제거 스크립트
# Version: 1.0.0
# ============================================

#Requires -RunAsAdministrator

# 스크립트 경로
$ScriptRoot = $PSScriptRoot

# 유틸리티 로드
. "$ScriptRoot\utils.ps1"

# 배너 출력
function Show-UninstallBanner {
    $banner = @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Windows 개발 환경 제거 스크립트                        ║
║   Development Environment Uninstaller                    ║
║                                                           ║
║   Version: 1.0.0                                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Red
}

Show-UninstallBanner

# 관리자 권한 확인
Require-Administrator

# ============================================
# 제거 대상 정의
# ============================================

$ChocolateyPackages = @(
    "git",
    "gh",
    "nvm",
    "python",
    "openjdk",
    "maven",
    "gradle",
    "docker-desktop",
    "vscode",
    "postgresql",
    "mysql",
    "mongodb",
    "redis-64",
    "sqlitestudio",
    "postman",
    "heidisql",
    "notepadplusplus",
    "googlechrome",
    "figma",
    "powershell-core",
    "microsoft-windows-terminal",
    "oh-my-posh"
)

$NpmGlobalPackages = @(
    "yarn",
    "pnpm",
    "typescript",
    "ts-node",
    "nodemon",
    "pm2",
    "http-server",
    "live-server",
    "prettier",
    "eslint"
)

$WindowsServices = @(
    @{Pattern="postgresql*"; Name="PostgreSQL"},
    @{Pattern="MySQL*"; Name="MySQL"},
    @{Pattern="MongoDB*"; Name="MongoDB"},
    @{Pattern="Redis*"; Name="Redis"}
)

# ============================================
# 제거 함수
# ============================================

function Stop-DatabaseServices {
    Write-Log "데이터베이스 서비스 중지 중..." -Level INFO

    foreach ($svc in $WindowsServices) {
        try {
            $service = Get-Service -Name $svc.Pattern -ErrorAction SilentlyContinue
            if ($service) {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                Write-Log "$($svc.Name) 서비스 중지됨" -Level SUCCESS
            }
        } catch {
            Write-Log "$($svc.Name) 서비스 중지 실패: $($_.Exception.Message)" -Level WARNING
        }
    }
}

function Remove-ChocolateyPackages {
    Write-Log "Chocolatey 패키지 제거 중..." -Level INFO

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Chocolatey가 설치되어 있지 않습니다." -Level WARNING
        return
    }

    $total = $ChocolateyPackages.Count
    $current = 0

    foreach ($package in $ChocolateyPackages) {
        $current++
        Write-Log "[$current/$total] $package 제거 중..." -Level INFO

        try {
            $result = choco uninstall $package -y --force 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$package 제거 완료" -Level SUCCESS
            } else {
                Write-Log "$package 제거 실패 또는 설치되어 있지 않음" -Level WARNING
            }
        } catch {
            Write-Log "$package 제거 중 오류: $($_.Exception.Message)" -Level ERROR
        }
    }
}

function Remove-NpmGlobalPackages {
    Write-Log "npm 전역 패키지 제거 중..." -Level INFO

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Log "npm이 설치되어 있지 않습니다." -Level WARNING
        return
    }

    foreach ($package in $NpmGlobalPackages) {
        try {
            npm uninstall -g $package 2>&1 | Out-Null
            Write-Log "$package 제거됨" -Level SUCCESS
        } catch {
            Write-Log "$package 제거 실패" -Level WARNING
        }
    }
}

function Remove-EnvironmentPaths {
    Write-Log "환경 변수 정리 중..." -Level INFO

    $pathsToRemove = @(
        "C:\Program Files\Git",
        "C:\Program Files\nodejs",
        "C:\Python*",
        "C:\Program Files\Java",
        "C:\ProgramData\chocolatey",
        "C:\Program Files\Docker",
        "C:\Program Files\PostgreSQL",
        "C:\Program Files\MySQL",
        "C:\Program Files\MongoDB",
        "C:\eGovFrameDev-3.10.0"
    )

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pathParts = $currentPath -split ";"

    $newPathParts = $pathParts | Where-Object {
        $part = $_
        $shouldRemove = $false
        foreach ($pattern in $pathsToRemove) {
            if ($part -like "$pattern*") {
                $shouldRemove = $true
                Write-Log "PATH에서 제거: $part" -Level INFO
                break
            }
        }
        -not $shouldRemove
    }

    $newPath = $newPathParts -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

    Write-Log "환경 변수 정리 완료" -Level SUCCESS
}

function Remove-ConfigurationFiles {
    Write-Log "설정 파일 제거 중..." -Level INFO

    $configPaths = @(
        "$env:USERPROFILE\.gitconfig",
        "$env:USERPROFILE\.npmrc",
        "$env:USERPROFILE\.prettierrc",
        "$env:USERPROFILE\.eslintrc.json",
        "$env:APPDATA\Code",
        "$env:USERPROFILE\.vscode"
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-Log "제거됨: $path" -Level SUCCESS
            } catch {
                Write-Log "제거 실패: $path - $($_.Exception.Message)" -Level WARNING
            }
        }
    }
}

function Remove-Chocolatey {
    Write-Log "Chocolatey 제거 중..." -Level INFO

    $chocoPath = "$env:ProgramData\chocolatey"
    
    if (Test-Path $chocoPath) {
        try {
            Remove-Item -Path $chocoPath -Recurse -Force -ErrorAction Stop
            Write-Log "Chocolatey 제거 완료" -Level SUCCESS
        } catch {
            Write-Log "Chocolatey 제거 실패: $($_.Exception.Message)" -Level ERROR
        }
    }

    # 환경 변수에서 Chocolatey 제거
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = ($machinePath -split ";" | Where-Object { $_ -notlike "*chocolatey*" }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
}

# ============================================
# 메뉴
# ============================================

function Show-UninstallMenu {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "    제거 옵션 선택" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  [1] 전체 제거 (모든 개발 도구)" -ForegroundColor White
    Write-Host "  [2] 선택적 제거" -ForegroundColor White
    Write-Host "  [3] 설정 파일만 제거" -ForegroundColor White
    Write-Host "  [4] 데이터베이스만 제거" -ForegroundColor White
    Write-Host "  [0] 취소" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
}

function Start-FullUninstall {
    Write-Host ""
    Write-Host "⚠️  경고: 모든 개발 도구와 설정이 제거됩니다!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "정말로 진행하시겠습니까? (YES 입력)"
    
    if ($confirm -ne "YES") {
        Write-Log "제거가 취소되었습니다." -Level INFO
        return
    }

    Write-Log "전체 제거를 시작합니다..." -Level WARNING

    Stop-DatabaseServices
    Remove-NpmGlobalPackages
    Remove-ChocolateyPackages
    Remove-ConfigurationFiles
    Remove-EnvironmentPaths
    Remove-Chocolatey

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  제거가 완료되었습니다!" -ForegroundColor Green
    Write-Host "  시스템 재시작을 권장합니다." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

function Start-SelectiveUninstall {
    Write-Host "`n선택적 제거:" -ForegroundColor Cyan
    Write-Host ""

    if (Confirm-Action "Chocolatey 패키지 제거?" -DefaultYes $false) {
        Remove-ChocolateyPackages
    }

    if (Confirm-Action "npm 전역 패키지 제거?" -DefaultYes $false) {
        Remove-NpmGlobalPackages
    }

    if (Confirm-Action "데이터베이스 서비스 중지 및 제거?" -DefaultYes $false) {
        Stop-DatabaseServices
    }

    if (Confirm-Action "설정 파일 제거?" -DefaultYes $false) {
        Remove-ConfigurationFiles
    }

    if (Confirm-Action "환경 변수 정리?" -DefaultYes $false) {
        Remove-EnvironmentPaths
    }

    Write-Log "선택적 제거 완료" -Level SUCCESS
}

function Start-DatabaseOnlyUninstall {
    Write-Log "데이터베이스 제거를 시작합니다..." -Level INFO

    Stop-DatabaseServices

    $dbPackages = @("postgresql", "mysql", "mongodb", "redis-64", "sqlitestudio")
    
    foreach ($package in $dbPackages) {
        if (Confirm-Action "$package 제거?" -DefaultYes $true) {
            choco uninstall $package -y --force 2>&1 | Out-Null
            Write-Log "$package 제거됨" -Level SUCCESS
        }
    }

    Write-Log "데이터베이스 제거 완료" -Level SUCCESS
}

# ============================================
# 메인 실행
# ============================================

function Start-Uninstaller {
    while ($true) {
        Show-UninstallMenu
        $choice = Read-Host "선택 (0-4)"

        switch ($choice) {
            "1" { Start-FullUninstall; break }
            "2" { Start-SelectiveUninstall; break }
            "3" { Remove-ConfigurationFiles; break }
            "4" { Start-DatabaseOnlyUninstall; break }
            "0" { 
                Write-Log "제거를 취소합니다." -Level INFO
                exit 0
            }
            default {
                Write-Log "잘못된 선택입니다." -Level WARNING
                continue
            }
        }
        break
    }
}

# 실행
try {
    Start-Uninstaller
} catch {
    Write-Log "오류 발생: $($_.Exception.Message)" -Level ERROR
    exit 1
}
