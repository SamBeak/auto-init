# ============================================
# 데이터베이스 설치 및 설정
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-PostgreSQL {
    param(
        [string]$Port = "5432",
        [string]$Username = "postgres",
        [string]$Password = "postgres"
    )

    Write-Log "PostgreSQL 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "PostgreSQL") {
        Write-Log "PostgreSQL이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "postgresql" -Params @("--params", "/Password:$Password")

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "PostgreSQL 설치 완료" -Level SUCCESS
        Write-Log "포트: $Port, 사용자: $Username" -Level INFO

        # 설정 정보 저장
        $configInfo = @"

PostgreSQL 접속 정보:
- 포트: $Port
- 사용자: $Username
- 비밀번호: ****
- 연결 문자열: postgresql://$Username:****@localhost:$Port/postgres
"@
        Add-Content -Path (Join-Path $PSScriptRoot "..\logs\db_config.txt") -Value $configInfo

        return $true
    }

    return $false
}

function Install-MySQL {
    param(
        [string]$Port = "3306",
        [string]$Username = "root",
        [string]$Password = "root"
    )

    Write-Log "MySQL 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "MySQL") {
        Write-Log "MySQL이 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "mysql"

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Log "MySQL 설치 완료" -Level SUCCESS
        Write-Log "포트: $Port, Root 사용자: $Username" -Level INFO

        # 설정 정보 저장
        $configInfo = @"

MySQL 접속 정보:
- 포트: $Port
- Root 사용자: $Username
- Root 비밀번호: ****
- 연결 문자열: mysql://$Username:****@localhost:$Port/
"@
        Add-Content -Path (Join-Path $PSScriptRoot "..\logs\db_config.txt") -Value $configInfo

        Write-Log "MySQL을 실행하여 초기 설정을 완료하세요." -Level INFO
        return $true
    }

    return $false
}

function Install-MongoDB {
    param(
        [string]$Port = "27017",
        [string]$Username = "admin",
        [string]$Password = "admin"
    )

    Write-Log "MongoDB 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "MongoDB") {
        Write-Log "MongoDB가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "mongodb"

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        # MongoDB 데이터 디렉토리 생성
        $mongoDataDir = "C:\data\db"
        if (-not (Test-Path $mongoDataDir)) {
            New-Item -ItemType Directory -Path $mongoDataDir -Force | Out-Null
            Write-Log "MongoDB 데이터 디렉토리 생성: $mongoDataDir" -Level INFO
        }

        Write-Log "MongoDB 설치 완료" -Level SUCCESS
        Write-Log "포트: $Port, 관리자: $Username" -Level INFO

        # 설정 정보 저장
        $configInfo = @"

MongoDB 접속 정보:
- 포트: $Port
- 관리자 사용자: $Username
- 관리자 비밀번호: ****
- 연결 문자열: mongodb://$Username:****@localhost:$Port/
"@
        Add-Content -Path (Join-Path $PSScriptRoot "..\logs\db_config.txt") -Value $configInfo

        return $true
    }

    return $false
}

function Install-Redis {
    param(
        [string]$Port = "6379",
        [string]$Password = ""
    )

    Write-Log "Redis 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "Redis") {
        Write-Log "Redis가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치 (Windows용 Redis)
    $result = Install-ChocolateyPackage -PackageName "redis-64"

    if ($result) {
        Write-Log "Redis 설치 완료" -Level SUCCESS
        Write-Log "포트: $Port" -Level INFO

        # 설정 정보 저장
        $configInfo = @"

Redis 접속 정보:
- 포트: $Port
- 비밀번호: $(if ([string]::IsNullOrWhiteSpace($Password)) { "없음 (비밀번호 미설정)" } else { "****" })
- 연결 문자열: redis://localhost:$Port
"@
        Add-Content -Path (Join-Path $PSScriptRoot "..\logs\db_config.txt") -Value $configInfo

        return $true
    }

    return $false
}

function Install-SQLiteStudio {
    Write-Log "SQLite Studio 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -ProgramName "SQLiteStudio") {
        Write-Log "SQLite Studio가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "sqlitestudio"

    if ($result) {
        Write-Log "SQLite Studio 설치 완료" -Level SUCCESS
        return $true
    }

    return $false
}

function Start-DatabaseServices {
    Write-Log "데이터베이스 서비스 시작 중..." -Level INFO

    # PostgreSQL 서비스 이름 동적 탐지
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
    $pgServiceName = if ($pgService) { $pgService.Name } else { "postgresql-x64-17" }

    $services = @(
        @{Name=$pgServiceName; DisplayName="PostgreSQL"},
        @{Name="MySQL"; DisplayName="MySQL"},
        @{Name="MongoDB"; DisplayName="MongoDB"},
        @{Name="Redis"; DisplayName="Redis"}
    )

    foreach ($svc in $services) {
        try {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

            if ($service) {
                if ($service.Status -ne 'Running') {
                    Start-Service -Name $svc.Name
                    Write-Log "$($svc.DisplayName) 서비스 시작됨" -Level SUCCESS
                } else {
                    Write-Log "$($svc.DisplayName) 서비스가 이미 실행 중입니다." -Level INFO
                }
            } else {
                Write-Log "$($svc.DisplayName) 서비스를 찾을 수 없습니다." -Level WARNING
            }

        } catch {
            Write-Log "$($svc.DisplayName) 서비스 시작 실패: $($_.Exception.Message)" -Level ERROR
        }
    }
}

function Set-DatabaseAutoStart {
    Write-Log "데이터베이스 자동 시작 설정 중..." -Level INFO

    # PostgreSQL 서비스 이름 동적 탐지
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
    $pgServiceName = if ($pgService) { $pgService.Name } else { "postgresql-x64-17" }

    $services = @($pgServiceName, "MySQL", "MongoDB", "Redis")

    foreach ($serviceName in $services) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

            if ($service) {
                Set-Service -Name $serviceName -StartupType Automatic
                Write-Log "$serviceName 자동 시작 설정 완료" -Level SUCCESS
            }

        } catch {
            Write-Log "$serviceName 자동 시작 설정 실패: $($_.Exception.Message)" -Level WARNING
        }
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Install-PostgreSQL
    Install-MySQL
    Install-MongoDB
    Install-Redis
    Install-SQLiteStudio
    Start-DatabaseServices
    Set-DatabaseAutoStart
}
