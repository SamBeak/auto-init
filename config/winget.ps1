# ============================================
# Winget 패키지 관리자 설정 및 사용
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"

function Test-WingetAvailable {
    try {
        $null = winget --version 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Source = "winget",
        [switch]$Silent = $true
    )

    Write-Log "Winget으로 $PackageId 설치 중..." -Level INFO

    if (-not (Test-WingetAvailable)) {
        Write-Log "Winget을 사용할 수 없습니다. Windows 10 1809+ 또는 Windows 11이 필요합니다." -Level WARNING
        return $false
    }

    try {
        $args = @("install", "--id", $PackageId, "--source", $Source, "--accept-package-agreements", "--accept-source-agreements")

        if ($Silent) {
            $args += "--silent"
        }

        $process = Start-Process -FilePath "winget" -ArgumentList $args -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Log "$PackageId 설치 완료" -Level SUCCESS
            return $true
        } else {
            Write-Log "$PackageId 설치 실패 (Exit Code: $($process.ExitCode))" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "$PackageId 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-WingetPackages {
    Write-Log "모든 Winget 패키지 업데이트 중..." -Level INFO

    if (-not (Test-WingetAvailable)) {
        Write-Log "Winget을 사용할 수 없습니다." -Level WARNING
        return $false
    }

    try {
        winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
        Write-Log "패키지 업데이트 완료" -Level SUCCESS
        return $true
    } catch {
        Write-Log "패키지 업데이트 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Search-WingetPackage {
    param(
        [string]$Query
    )

    if (-not (Test-WingetAvailable)) {
        Write-Log "Winget을 사용할 수 없습니다." -Level WARNING
        return $null
    }

    try {
        $result = winget search $Query
        return $result
    } catch {
        Write-Log "패키지 검색 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    if (Test-WingetAvailable) {
        Write-Log "Winget이 사용 가능합니다." -Level SUCCESS
        $version = winget --version
        Write-Log "버전: $version" -Level INFO
    } else {
        Write-Log "Winget을 사용할 수 없습니다." -Level WARNING
        Write-Log "Microsoft Store에서 '앱 설치 관리자'를 설치하거나 Windows를 업데이트하세요." -Level INFO
    }
}
