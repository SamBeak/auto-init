# ============================================
# Chocolatey 패키지 관리자 설치 및 설정
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"

function Install-Chocolatey {
    Write-Log "Chocolatey 설치를 시작합니다..." -Level INFO

    # 이미 설치되어 있는지 확인
    if (Test-ProgramInstalled -CommandCheck "choco") {
        Write-Log "Chocolatey가 이미 설치되어 있습니다." -Level SUCCESS
        $version = choco --version
        Write-Log "현재 버전: $version" -Level INFO
        return $true
    }

    try {
        # 실행 정책 설정
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Chocolatey 설치
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        $installScript = Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # 설치 확인
        if (Test-ProgramInstalled -CommandCheck "choco") {
            Write-Log "Chocolatey 설치 완료!" -Level SUCCESS

            # Chocolatey 설정
            choco feature enable -n allowGlobalConfirmation
            Write-Log "자동 확인 기능 활성화" -Level INFO

            return $true
        } else {
            Write-Log "Chocolatey 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Chocolatey 설치 중 오류 발생: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-ChocolateyPackage {
    param(
        [string]$PackageName,
        [string]$Version = $null,
        [string[]]$Params = @()
    )

    Write-Log "Chocolatey로 $PackageName 설치 중..." -Level INFO

    try {
        $installCmd = "choco install $PackageName -y"

        if ($Version) {
            $installCmd += " --version=$Version"
        }

        if ($Params.Count -gt 0) {
            $installCmd += " --params=`"$($Params -join ' ')`""
        }

        Invoke-Expression $installCmd

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$PackageName 설치 완료" -Level SUCCESS
            return $true
        } else {
            Write-Log "$PackageName 설치 실패 (Exit Code: $LASTEXITCODE)" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "$PackageName 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-ChocolateyPackages {
    Write-Log "모든 Chocolatey 패키지 업데이트 중..." -Level INFO

    try {
        choco upgrade all -y
        Write-Log "패키지 업데이트 완료" -Level SUCCESS
        return $true
    } catch {
        Write-Log "패키지 업데이트 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-Chocolatey
}
