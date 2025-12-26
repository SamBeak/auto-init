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

function Install-Winget {
    Write-Log "Winget 설치를 확인합니다..." -Level INFO

    if (Test-WingetAvailable) {
        $version = winget --version
        Write-Log "Winget이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    Write-Log "Winget 설치를 시작합니다..." -Level INFO

    try {
        # Windows 11 또는 Windows 10 최신 버전은 winget이 기본 포함
        # 없는 경우 App Installer 패키지 설치

        # 임시 디렉토리
        $tempDir = Join-Path $env:TEMP "winget_install"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        # Microsoft.DesktopAppInstaller 다운로드
        Write-Log "App Installer 패키지 다운로드 중..." -Level INFO
        
        $appInstallerUrl = "https://aka.ms/getwinget"
        $appInstallerPath = Join-Path $tempDir "Microsoft.DesktopAppInstaller.msixbundle"
        
        # VCLibs 의존성 다운로드
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = Join-Path $tempDir "Microsoft.VCLibs.x64.14.00.Desktop.appx"

        # UI.Xaml 의존성 다운로드
        $xamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
        $xamlPath = Join-Path $tempDir "Microsoft.UI.Xaml.2.8.x64.appx"

        # 다운로드
        $webClient = New-Object System.Net.WebClient
        
        Write-Log "VCLibs 다운로드 중..." -Level INFO
        $webClient.DownloadFile($vcLibsUrl, $vcLibsPath)
        
        Write-Log "UI.Xaml 다운로드 중..." -Level INFO
        $webClient.DownloadFile($xamlUrl, $xamlPath)
        
        Write-Log "App Installer 다운로드 중..." -Level INFO
        $webClient.DownloadFile($appInstallerUrl, $appInstallerPath)

        # 의존성 설치
        Write-Log "의존성 패키지 설치 중..." -Level INFO
        Add-AppxPackage -Path $vcLibsPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $xamlPath -ErrorAction SilentlyContinue

        # App Installer 설치
        Write-Log "App Installer 설치 중..." -Level INFO
        Add-AppxPackage -Path $appInstallerPath

        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # 설치 확인
        Start-Sleep -Seconds 2
        
        if (Test-WingetAvailable) {
            $version = winget --version
            Write-Log "Winget 설치 완료: $version" -Level SUCCESS
            
            # 임시 파일 정리
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            
            return $true
        } else {
            Write-Log "Winget 설치 후 확인 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Winget 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        Write-Log "Microsoft Store에서 '앱 설치 관리자'를 수동으로 설치하세요." -Level WARNING
        return $false
    }
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$Source = "winget",
        [switch]$Silent
    )

    Write-Log "Winget으로 $PackageId 설치 중..." -Level INFO

    if (-not (Test-WingetAvailable)) {
        Write-Log "Winget을 사용할 수 없습니다. Windows 10 1809+ 또는 Windows 11이 필요합니다." -Level WARNING
        return $false
    }

    try {
        $wingetArgs = @("install", "--id", $PackageId, "--source", $Source, "--accept-package-agreements", "--accept-source-agreements")

        if ($Silent) {
            $wingetArgs += "--silent"
        }

        $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -NoNewWindow -Wait -PassThru

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
    # Winget 자동 설치 시도
    Install-Winget
}
