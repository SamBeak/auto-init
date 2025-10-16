# ============================================
# Java 및 빌드 도구 설치
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-Java {
    param(
        [string]$Version = "17"  # 8, 11, 17, 21 등
    )

    Write-Log "Java (OpenJDK) 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "java") {
        $currentVersion = java -version 2>&1 | Select-String "version" | Select-Object -First 1
        Write-Log "Java가 이미 설치되어 있습니다: $currentVersion" -Level SUCCESS
        return $true
    }

    # Chocolatey로 OpenJDK 설치
    $packageName = "openjdk$Version"
    $result = Install-ChocolateyPackage -PackageName $packageName

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # JAVA_HOME 설정
        $javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
        if ($javaHome) {
            Write-Log "JAVA_HOME: $javaHome" -Level INFO
        }

        $javaVersion = java -version 2>&1 | Select-String "version" | Select-Object -First 1
        Write-Log "Java 설치 완료: $javaVersion" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-Maven {
    Write-Log "Apache Maven 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "mvn") {
        $version = mvn --version | Select-String "Apache Maven" | Select-Object -First 1
        Write-Log "Maven이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    $result = Install-ChocolateyPackage -PackageName "maven"

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $version = mvn --version | Select-String "Apache Maven" | Select-Object -First 1
        Write-Log "Maven 설치 완료: $version" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-Gradle {
    Write-Log "Gradle 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "gradle") {
        $version = gradle --version | Select-String "Gradle" | Select-Object -First 1
        Write-Log "Gradle이 이미 설치되어 있습니다: $version" -Level SUCCESS
        return $true
    }

    $result = Install-ChocolateyPackage -PackageName "gradle"

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $version = gradle --version | Select-String "Gradle" | Select-Object -First 1
        Write-Log "Gradle 설치 완료: $version" -Level SUCCESS
        return $true
    }

    return $false
}

function Set-JavaEnvironment {
    Write-Log "Java 환경 변수 설정 중..." -Level INFO

    try {
        # JAVA_HOME이 설정되어 있는지 확인
        $javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")

        if (-not $javaHome) {
            # Java 설치 경로 찾기
            $javaPath = (Get-Command java -ErrorAction SilentlyContinue).Source

            if ($javaPath) {
                $javaHome = Split-Path (Split-Path $javaPath -Parent) -Parent
                [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
                Write-Log "JAVA_HOME 설정: $javaHome" -Level SUCCESS
            } else {
                Write-Log "Java 설치 경로를 찾을 수 없습니다." -Level WARNING
                return $false
            }
        } else {
            Write-Log "JAVA_HOME이 이미 설정되어 있습니다: $javaHome" -Level INFO
        }

        return $true

    } catch {
        Write-Log "Java 환경 변수 설정 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-Java
    Set-JavaEnvironment
    Install-Maven
    Install-Gradle
}
