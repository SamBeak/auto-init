# ============================================
# 전자정부프레임워크 3.10 설치
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"

function Install-EgovFramework {
    Write-Log "전자정부프레임워크 3.10 설치를 시작합니다..." -Level INFO

    # 전자정부프레임워크 설치 확인
    $egovPath = "C:\eGovFrameDev-3.10.0"
    if (Test-Path $egovPath) {
        Write-Log "전자정부프레임워크가 이미 설치되어 있습니다: $egovPath" -Level SUCCESS
        return $true
    }

    try {
        # 다운로드 URL (공식 사이트)
        $downloadUrl = "https://www.egovframe.go.kr/EgovDevInitImpl.do?cmd=downDevFile&version=3.10.0"
        $downloadPath = Join-Path $env:TEMP "eGovFrameDev-3.10.0.exe"

        Write-Log "전자정부프레임워크 다운로드 중..." -Level INFO
        Write-Log "다운로드 URL: $downloadUrl" -Level INFO

        # 다운로드
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $downloadPath)

        if (Test-Path $downloadPath) {
            Write-Log "다운로드 완료: $downloadPath" -Level SUCCESS

            # 설치 안내
            Write-Host "`n" -NoNewline
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "  전자정부프레임워크 설치 안내" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "다운로드가 완료되었습니다." -ForegroundColor Green
            Write-Host "설치 파일 위치: $downloadPath" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "설치를 진행하려면:" -ForegroundColor White
            Write-Host "1. 다운로드된 파일을 실행하세요." -ForegroundColor White
            Write-Host "2. 설치 경로를 C:\eGovFrameDev-3.10.0 으로 지정하세요." -ForegroundColor White
            Write-Host "3. 설치 완료 후 Eclipse를 실행하세요." -ForegroundColor White
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""

            # 자동 설치 시도 (사용자 선택)
            if (Confirm-Action "지금 설치를 진행하시겠습니까?" -DefaultYes $true) {
                Write-Log "설치 파일 실행 중..." -Level INFO
                Start-Process -FilePath $downloadPath -Wait

                if (Test-Path $egovPath) {
                    Write-Log "전자정부프레임워크 3.10 설치 완료!" -Level SUCCESS

                    # 환경 변수 추가
                    $eclipsePath = Join-Path $egovPath "eclipse"
                    if (Test-Path $eclipsePath) {
                        Add-PathVariable -Path $eclipsePath -Scope User
                        Write-Log "Eclipse 경로를 PATH에 추가했습니다." -Level INFO
                    }

                    return $true
                } else {
                    Write-Log "설치가 완료되지 않았습니다. 수동으로 설치해주세요." -Level WARNING
                    return $false
                }
            } else {
                Write-Log "설치를 건너뛰었습니다. 나중에 수동으로 설치해주세요." -Level INFO
                Write-Log "설치 파일: $downloadPath" -Level INFO
                return $true
            }

        } else {
            Write-Log "다운로드 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "전자정부프레임워크 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        Write-Log "공식 사이트에서 직접 다운로드: https://www.egovframe.go.kr/home/sub.do?menuNo=41" -Level INFO
        return $false
    }
}

function Install-EgovFrameworkAlternative {
    Write-Log "전자정부프레임워크 대체 설치 방법..." -Level INFO

    # Maven을 통한 전자정부 표준프레임워크 의존성 설정
    $settingsXmlPath = Join-Path $env:USERPROFILE ".m2\settings.xml"
    $settingsDir = Split-Path $settingsXmlPath -Parent

    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # Maven settings.xml 생성
    $settingsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">

    <profiles>
        <profile>
            <id>egovframe</id>
            <repositories>
                <repository>
                    <id>egovframe</id>
                    <url>https://maven.egovframe.go.kr/maven/</url>
                    <releases>
                        <enabled>true</enabled>
                    </releases>
                    <snapshots>
                        <enabled>false</enabled>
                    </snapshots>
                </repository>
            </repositories>
        </profile>
    </profiles>

    <activeProfiles>
        <activeProfile>egovframe</activeProfile>
    </activeProfiles>

</settings>
"@

    try {
        Set-Content -Path $settingsXmlPath -Value $settingsXml -Encoding UTF8
        Write-Log "Maven 전자정부프레임워크 저장소 설정 완료: $settingsXmlPath" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Maven 설정 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Show-EgovFrameworkInfo {
    Write-Host "`n" -NoNewline
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  전자정부프레임워크 3.10 정보" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "버전: 3.10.0" -ForegroundColor White
    Write-Host "기반: Eclipse, Spring Framework, MyBatis" -ForegroundColor White
    Write-Host ""
    Write-Host "포함 도구:" -ForegroundColor Yellow
    Write-Host "  - Eclipse IDE" -ForegroundColor White
    Write-Host "  - Tomcat 8.5" -ForegroundColor White
    Write-Host "  - Maven" -ForegroundColor White
    Write-Host "  - 전자정부 표준프레임워크 라이브러리" -ForegroundColor White
    Write-Host ""
    Write-Host "공식 사이트: https://www.egovframe.go.kr" -ForegroundColor Cyan
    Write-Host "개발자 가이드: https://www.egovframe.go.kr/home/sub.do?menuNo=74" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Show-EgovFrameworkInfo
    Install-EgovFramework
    Install-EgovFrameworkAlternative
}
