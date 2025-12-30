# ============================================
# 개발 환경 헬스 체크 스크립트
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 서비스 상태 체크
# ============================================

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$DisplayName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($service) {
            return @{
                Name = $DisplayName
                Status = $service.Status.ToString()
                Running = ($service.Status -eq 'Running')
            }
        } else {
            return @{
                Name = $DisplayName
                Status = "Not Installed"
                Running = $false
            }
        }
    } catch {
        return @{
            Name = $DisplayName
            Status = "Error"
            Running = $false
        }
    }
}

function Test-PortHealth {
    param(
        [string]$ServiceName,
        [int]$Port
    )
    
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        
        return @{
            Name = $ServiceName
            Port = $Port
            Open = $connection.TcpTestSucceeded
        }
    } catch {
        return @{
            Name = $ServiceName
            Port = $Port
            Open = $false
        }
    }
}

function Test-CommandAvailable {
    param(
        [string]$ToolName,
        [string]$Command,
        [string]$VersionArg = "--version"
    )
    
    try {
        $result = & $Command $VersionArg 2>&1 | Select-Object -First 1
        
        return @{
            Name = $ToolName
            Available = $true
            Version = $result.ToString().Trim()
        }
    } catch {
        return @{
            Name = $ToolName
            Available = $false
            Version = "N/A"
        }
    }
}

# ============================================
# 전체 헬스 체크
# ============================================

function Start-HealthCheck {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              개발 환경 헬스 체크                              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $healthResults = @{
        Tools = @()
        Services = @()
        Ports = @()
    }
    
    # ============================================
    # 1. 개발 도구 체크
    # ============================================
    
    Write-Host "📦 개발 도구 상태" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray
    
    $tools = @(
        @{Name="Git"; Command="git"; VersionArg="--version"},
        @{Name="Node.js"; Command="node"; VersionArg="--version"},
        @{Name="npm"; Command="npm"; VersionArg="--version"},
        @{Name="Python"; Command="python"; VersionArg="--version"},
        @{Name="pip"; Command="pip"; VersionArg="--version"},
        @{Name="Java"; Command="java"; VersionArg="-version"},
        @{Name="Docker"; Command="docker"; VersionArg="--version"},
        @{Name="VS Code"; Command="code"; VersionArg="--version"}
    )
    
    foreach ($tool in $tools) {
        $result = Test-CommandAvailable -ToolName $tool.Name -Command $tool.Command -VersionArg $tool.VersionArg
        $healthResults.Tools += $result
        
        if ($result.Available) {
            Write-Host "  ✅ " -ForegroundColor Green -NoNewline
            Write-Host "$($tool.Name): " -NoNewline
            Write-Host "$($result.Version)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ " -ForegroundColor Red -NoNewline
            Write-Host "$($tool.Name): 설치되지 않음" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    # ============================================
    # 2. 데이터베이스 서비스 체크
    # ============================================
    
    Write-Host "🗄️ 데이터베이스 서비스 상태" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray
    
    # PostgreSQL 서비스 동적 탐지
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
    $pgServiceName = if ($pgService) { $pgService.Name } else { "postgresql-x64-17" }
    
    $services = @(
        @{Name=$pgServiceName; DisplayName="PostgreSQL"},
        @{Name="MySQL"; DisplayName="MySQL"},
        @{Name="MongoDB"; DisplayName="MongoDB"},
        @{Name="Redis"; DisplayName="Redis"}
    )
    
    foreach ($service in $services) {
        $result = Test-ServiceHealth -ServiceName $service.Name -DisplayName $service.DisplayName
        $healthResults.Services += $result
        
        if ($result.Running) {
            Write-Host "  ✅ " -ForegroundColor Green -NoNewline
            Write-Host "$($service.DisplayName): " -NoNewline
            Write-Host "Running" -ForegroundColor Green
        } elseif ($result.Status -eq "Not Installed") {
            Write-Host "  ⬚ " -ForegroundColor Gray -NoNewline
            Write-Host "$($service.DisplayName): " -NoNewline
            Write-Host "설치되지 않음" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠️ " -ForegroundColor Yellow -NoNewline
            Write-Host "$($service.DisplayName): " -NoNewline
            Write-Host "$($result.Status)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # ============================================
    # 3. 포트 연결 체크
    # ============================================
    
    Write-Host "🔌 포트 연결 상태" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray
    
    $ports = @(
        @{Name="PostgreSQL"; Port=5432},
        @{Name="MySQL"; Port=3306},
        @{Name="MongoDB"; Port=27017},
        @{Name="Redis"; Port=6379}
    )
    
    foreach ($port in $ports) {
        $result = Test-PortHealth -ServiceName $port.Name -Port $port.Port
        $healthResults.Ports += $result
        
        if ($result.Open) {
            Write-Host "  ✅ " -ForegroundColor Green -NoNewline
            Write-Host "$($port.Name) (포트 $($port.Port)): " -NoNewline
            Write-Host "연결 가능" -ForegroundColor Green
        } else {
            Write-Host "  ❌ " -ForegroundColor Red -NoNewline
            Write-Host "$($port.Name) (포트 $($port.Port)): " -NoNewline
            Write-Host "연결 불가" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    # ============================================
    # 4. 환경 변수 체크
    # ============================================
    
    Write-Host "🔧 환경 변수 상태" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray
    
    $envVars = @(
        @{Name="JAVA_HOME"; Required=$false},
        @{Name="PYTHON_HOME"; Required=$false},
        @{Name="NVM_HOME"; Required=$false},
        @{Name="DOCKER_HOST"; Required=$false}
    )
    
    foreach ($env in $envVars) {
        $value = [System.Environment]::GetEnvironmentVariable($env.Name, "Machine")
        if (-not $value) {
            $value = [System.Environment]::GetEnvironmentVariable($env.Name, "User")
        }
        
        if ($value) {
            Write-Host "  ✅ " -ForegroundColor Green -NoNewline
            Write-Host "$($env.Name): " -NoNewline
            Write-Host "$value" -ForegroundColor Gray
        } else {
            $icon = if ($env.Required) { "❌" } else { "⬚" }
            $color = if ($env.Required) { "Red" } else { "Gray" }
            Write-Host "  $icon " -ForegroundColor $color -NoNewline
            Write-Host "$($env.Name): " -NoNewline
            Write-Host "설정되지 않음" -ForegroundColor $color
        }
    }
    
    Write-Host ""
    
    # ============================================
    # 5. 디스크 공간 체크
    # ============================================
    
    Write-Host "💾 디스크 공간" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray
    
    $drive = Get-PSDrive -Name C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
    $usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
    
    $color = if ($freeGB -lt 10) { "Red" } elseif ($freeGB -lt 30) { "Yellow" } else { "Green" }
    $icon = if ($freeGB -lt 10) { "❌" } elseif ($freeGB -lt 30) { "⚠️" } else { "✅" }
    
    Write-Host "  $icon " -ForegroundColor $color -NoNewline
    Write-Host "C: 드라이브 - 사용: ${usedGB}GB / ${totalGB}GB (${usedPercent}%), 남은 공간: ${freeGB}GB" -ForegroundColor $color
    
    Write-Host ""
    
    # ============================================
    # 요약
    # ============================================
    
    $toolsOk = ($healthResults.Tools | Where-Object { $_.Available }).Count
    $toolsTotal = $healthResults.Tools.Count
    $servicesOk = ($healthResults.Services | Where-Object { $_.Running }).Count
    $servicesTotal = ($healthResults.Services | Where-Object { $_.Status -ne "Not Installed" }).Count
    $portsOk = ($healthResults.Ports | Where-Object { $_.Open }).Count
    $portsTotal = $healthResults.Ports.Count
    
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  요약: 도구 $toolsOk/$toolsTotal | 서비스 $servicesOk/$servicesTotal | 포트 $portsOk/$portsTotal                        ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    return $healthResults
}

# ============================================
# 서비스 시작/중지 유틸리티
# ============================================

function Start-DatabaseService {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($service) {
            if ($service.Status -ne 'Running') {
                Write-Log "$ServiceName 서비스 시작 중..." -Level INFO
                Start-Service -Name $ServiceName
                Write-Log "$ServiceName 서비스가 시작되었습니다." -Level SUCCESS
            } else {
                Write-Log "$ServiceName 서비스가 이미 실행 중입니다." -Level INFO
            }
            return $true
        } else {
            Write-Log "$ServiceName 서비스를 찾을 수 없습니다." -Level WARNING
            return $false
        }
    } catch {
        Write-Log "$ServiceName 서비스 시작 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Stop-DatabaseService {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        
        if ($service) {
            if ($service.Status -eq 'Running') {
                Write-Log "$ServiceName 서비스 중지 중..." -Level INFO
                Stop-Service -Name $ServiceName -Force
                Write-Log "$ServiceName 서비스가 중지되었습니다." -Level SUCCESS
            } else {
                Write-Log "$ServiceName 서비스가 이미 중지되어 있습니다." -Level INFO
            }
            return $true
        } else {
            Write-Log "$ServiceName 서비스를 찾을 수 없습니다." -Level WARNING
            return $false
        }
    } catch {
        Write-Log "$ServiceName 서비스 중지 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Restart-AllDatabaseServices {
    Write-Log "모든 데이터베이스 서비스 재시작 중..." -Level INFO
    
    # PostgreSQL 동적 탐지
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pgService) {
        Restart-Service -Name $pgService.Name -Force -ErrorAction SilentlyContinue
    }
    
    $services = @("MySQL", "MongoDB", "Redis")
    
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            try {
                Restart-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                Write-Log "$serviceName 재시작 완료" -Level SUCCESS
            } catch {
                Write-Log "$serviceName 재시작 실패: $($_.Exception.Message)" -Level WARNING
            }
        }
    }
    
    Write-Log "데이터베이스 서비스 재시작 완료" -Level SUCCESS
}

# ============================================
# 메인 메뉴
# ============================================

function Show-HealthCheckMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    헬스 체크 메뉴" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 전체 헬스 체크 실행" -ForegroundColor White
    Write-Host "  [2] 모든 DB 서비스 시작" -ForegroundColor White
    Write-Host "  [3] 모든 DB 서비스 중지" -ForegroundColor White
    Write-Host "  [4] 모든 DB 서비스 재시작" -ForegroundColor White
    Write-Host "  [0] 종료" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Start-HealthCheckMenu {
    while ($true) {
        Show-HealthCheckMenu
        $choice = Read-Host "선택 (0-4)"
        
        switch ($choice) {
            "1" {
                Start-HealthCheck
            }
            "2" {
                # PostgreSQL 동적 탐지
                $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($pgService) { Start-DatabaseService -ServiceName $pgService.Name }
                
                Start-DatabaseService -ServiceName "MySQL"
                Start-DatabaseService -ServiceName "MongoDB"
                Start-DatabaseService -ServiceName "Redis"
            }
            "3" {
                # PostgreSQL 동적 탐지
                $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($pgService) { Stop-DatabaseService -ServiceName $pgService.Name }
                
                Stop-DatabaseService -ServiceName "MySQL"
                Stop-DatabaseService -ServiceName "MongoDB"
                Stop-DatabaseService -ServiceName "Redis"
            }
            "4" {
                Restart-AllDatabaseServices
            }
            "0" {
                Write-Log "헬스 체크를 종료합니다." -Level INFO
                return
            }
            default {
                Write-Log "잘못된 선택입니다." -Level WARNING
            }
        }
        
        Write-Host ""
        Read-Host "계속하려면 Enter를 누르세요..."
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Start-HealthCheckMenu
}
