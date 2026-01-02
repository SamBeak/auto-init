# ============================================
# 병렬 설치 모듈
# Version: 1.0.0
# Description: 독립적인 도구들을 동시에 설치하여 설치 시간을 단축합니다.
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 병렬 설치 그룹 정의
# ============================================

<#
.SYNOPSIS
    병렬 설치가 가능한 도구 그룹을 정의합니다.
.DESCRIPTION
    서로 의존성이 없는 도구들을 그룹으로 묶어 동시 설치를 가능하게 합니다.
    각 그룹 내 도구들은 동시에 설치되고, 그룹 간에는 순차적으로 진행됩니다.
#>
$global:ParallelInstallGroups = @(
    # 그룹 1: 패키지 관리자 (먼저 설치 - 순차)
    @{
        Name = "패키지 관리자"
        Parallel = $false
        Tools = @("chocolatey", "winget")
    },
    # 그룹 2: 기본 도구들 (병렬 가능)
    @{
        Name = "기본 도구"
        Parallel = $true
        Tools = @("git", "powershell7", "windows-terminal")
    },
    # 그룹 3: 런타임 환경 (병렬 가능)
    @{
        Name = "런타임 환경"
        Parallel = $true
        Tools = @("nvm", "python", "java")
    },
    # 그룹 4: 컨테이너 및 가상화 (순차 - WSL 의존성)
    @{
        Name = "컨테이너"
        Parallel = $false
        Tools = @("docker")
    },
    # 그룹 5: IDE 및 에디터 (병렬 가능)
    @{
        Name = "IDE & 에디터"
        Parallel = $true
        Tools = @("vscode", "notepadplusplus")
    },
    # 그룹 6: 데이터베이스 (병렬 가능)
    @{
        Name = "데이터베이스"
        Parallel = $true
        Tools = @("postgresql", "mysql", "mongodb", "redis")
    },
    # 그룹 7: 추가 도구 (병렬 가능)
    @{
        Name = "추가 도구"
        Parallel = $true
        Tools = @("postman", "heidisql", "oh-my-posh", "ngrok", "kubectl", "obsidian")
    },
    # 그룹 8: 코드 품질 도구 (Node.js 의존 - 순차)
    @{
        Name = "코드 품질"
        Parallel = $false
        Tools = @("prettier", "eslint")
    }
)

# 도구별 설치 스크립트 매핑
$global:ToolInstallers = @{
    "chocolatey" = { & "$PSScriptRoot\..\config\chocolatey.ps1" }
    "winget" = { & "$PSScriptRoot\..\config\winget.ps1" }
    "git" = { & "$PSScriptRoot\..\config\git.ps1" }
    "nvm" = { 
        . "$PSScriptRoot\..\config\node.ps1"
        Install-NVM
        Install-NodeJS
    }
    "python" = { & "$PSScriptRoot\..\config\python.ps1" }
    "java" = { & "$PSScriptRoot\..\config\java.ps1" }
    "docker" = { & "$PSScriptRoot\..\config\docker.ps1" }
    "vscode" = { & "$PSScriptRoot\..\config\vscode.ps1" }
    "postgresql" = {
        . "$PSScriptRoot\..\config\database.ps1"
        Install-PostgreSQL
    }
    "mysql" = {
        . "$PSScriptRoot\..\config\database.ps1"
        Install-MySQL
    }
    "mongodb" = {
        . "$PSScriptRoot\..\config\database.ps1"
        Install-MongoDB
    }
    "redis" = {
        . "$PSScriptRoot\..\config\database.ps1"
        Install-Redis
    }
    "postman" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-Postman
    }
    "heidisql" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-HeidiSQL
    }
    "oh-my-posh" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-OhMyPosh
    }
    "ngrok" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-Ngrok
    }
    "kubectl" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-Kubectl
    }
    "powershell7" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-PowerShell7
    }
    "windows-terminal" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-WindowsTerminal
    }
    "notepadplusplus" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-NotepadPlusPlus
    }
    "prettier" = {
        . "$PSScriptRoot\..\config\linters.ps1"
        Install-Prettier
    }
    "eslint" = {
        . "$PSScriptRoot\..\config\linters.ps1"
        Install-ESLint
    }
    "obsidian" = {
        . "$PSScriptRoot\..\config\tools.ps1"
        Install-Obsidian
    }
}

# ============================================
# 병렬 설치 함수
# ============================================

<#
.SYNOPSIS
    단일 도구를 백그라운드 작업으로 설치합니다.
.PARAMETER ToolName
    설치할 도구 이름
.PARAMETER ScriptBlock
    설치 스크립트 블록
.OUTPUTS
    [System.Management.Automation.Job] 백그라운드 작업 객체
#>
function Start-ToolInstallJob {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )
    
    $job = Start-Job -Name "Install_$ToolName" -ScriptBlock {
        param($ScriptRoot, $ToolName, $InstallScript)
        
        try {
            # 유틸리티 로드
            . "$ScriptRoot\utils.ps1"
            
            # 설치 실행
            $result = Invoke-Command -ScriptBlock ([scriptblock]::Create($InstallScript))
            
            return @{
                ToolName = $ToolName
                Success = $true
                Message = "설치 완료"
            }
        } catch {
            return @{
                ToolName = $ToolName
                Success = $false
                Message = $_.Exception.Message
            }
        }
    } -ArgumentList $PSScriptRoot, $ToolName, $ScriptBlock.ToString()
    
    return $job
}

<#
.SYNOPSIS
    도구 그룹을 병렬로 설치합니다.
.PARAMETER Tools
    설치할 도구 이름 배열
.PARAMETER MaxConcurrent
    최대 동시 설치 수
.OUTPUTS
    [hashtable] 설치 결과
#>
function Install-ToolsParallel {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tools,
        
        [int]$MaxConcurrent = 4
    )
    
    $results = @{
        Success = @()
        Failed = @()
    }
    
    $jobs = @()
    $toolQueue = [System.Collections.Queue]::new($Tools)
    
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  병렬 설치 시작 (최대 동시 실행: $MaxConcurrent)                  │" -ForegroundColor Cyan
    Write-Host "│  대상 도구: $($Tools -join ', ')".PadRight(50) + "│" -ForegroundColor White
    Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    
    while ($toolQueue.Count -gt 0 -or $jobs.Count -gt 0) {
        # 새 작업 시작 (큐에 도구가 있고 동시 실행 제한 이내인 경우)
        while ($toolQueue.Count -gt 0 -and $jobs.Count -lt $MaxConcurrent) {
            $toolName = $toolQueue.Dequeue()
            
            if ($global:ToolInstallers.ContainsKey($toolName)) {
                Write-Host "  ▶ 시작: $toolName" -ForegroundColor Yellow
                $job = Start-ToolInstallJob -ToolName $toolName -ScriptBlock $global:ToolInstallers[$toolName]
                $jobs += $job
            } else {
                Write-Host "  ⚠ 설치 스크립트 없음: $toolName" -ForegroundColor DarkYellow
                $results.Failed += @{ Name = $toolName; Message = "설치 스크립트 없음" }
            }
        }
        
        # 완료된 작업 확인
        $completedJobs = $jobs | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
        
        foreach ($job in $completedJobs) {
            $toolName = $job.Name -replace 'Install_', ''
            
            try {
                $jobResult = Receive-Job -Job $job -ErrorAction SilentlyContinue
                
                if ($job.State -eq 'Completed' -and $jobResult.Success) {
                    Write-Host "  ✅ 완료: $toolName" -ForegroundColor Green
                    $results.Success += @{ Name = $toolName; Message = "성공" }
                    Add-InstallResult -ToolName $toolName -Status Success
                } else {
                    $errorMsg = if ($jobResult.Message) { $jobResult.Message } else { "알 수 없는 오류" }
                    Write-Host "  ❌ 실패: $toolName - $errorMsg" -ForegroundColor Red
                    $results.Failed += @{ Name = $toolName; Message = $errorMsg }
                    Add-InstallResult -ToolName $toolName -Status Failed -Message $errorMsg
                }
            } catch {
                Write-Host "  ❌ 실패: $toolName - $($_.Exception.Message)" -ForegroundColor Red
                $results.Failed += @{ Name = $toolName; Message = $_.Exception.Message }
                Add-InstallResult -ToolName $toolName -Status Failed -Message $_.Exception.Message
            }
            
            Remove-Job -Job $job -Force
            $jobs = $jobs | Where-Object { $_.Id -ne $job.Id }
        }
        
        # 아직 실행 중인 작업이 있으면 대기
        if ($jobs.Count -gt 0) {
            Start-Sleep -Milliseconds 500
            
            # 실행 중인 작업 표시
            $runningTools = ($jobs | ForEach-Object { $_.Name -replace 'Install_', '' }) -join ', '
            Write-Host "`r  ⏳ 설치 중: $runningTools" -NoNewline -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    return $results
}

<#
.SYNOPSIS
    도구 그룹을 순차적으로 설치합니다.
.PARAMETER Tools
    설치할 도구 이름 배열
.OUTPUTS
    [hashtable] 설치 결과
#>
function Install-ToolsSequential {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tools
    )
    
    $results = @{
        Success = @()
        Failed = @()
    }
    
    foreach ($toolName in $Tools) {
        if ($global:ToolInstallers.ContainsKey($toolName)) {
            Write-Host "  ▶ 설치 중: $toolName" -ForegroundColor Yellow
            
            try {
                & $global:ToolInstallers[$toolName]
                Write-Host "  ✅ 완료: $toolName" -ForegroundColor Green
                $results.Success += @{ Name = $toolName; Message = "성공" }
                Add-InstallResult -ToolName $toolName -Status Success
            } catch {
                Write-Host "  ❌ 실패: $toolName - $($_.Exception.Message)" -ForegroundColor Red
                $results.Failed += @{ Name = $toolName; Message = $_.Exception.Message }
                Add-InstallResult -ToolName $toolName -Status Failed -Message $_.Exception.Message
            }
        } else {
            Write-Host "  ⚠ 설치 스크립트 없음: $toolName" -ForegroundColor DarkYellow
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    전체 설치를 병렬/순차 혼합으로 진행합니다.
.PARAMETER ToolsToInstall
    설치할 도구 목록
.PARAMETER EnableParallel
    병렬 설치 활성화 여부
.PARAMETER MaxConcurrent
    최대 동시 설치 수
#>
function Start-OptimizedInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ToolsToInstall,
        
        [bool]$EnableParallel = $true,
        
        [int]$MaxConcurrent = 4
    )
    
    $startTime = Get-Date
    $totalResults = @{
        Success = @()
        Failed = @()
    }
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           최적화된 설치 시작                          ║" -ForegroundColor Cyan
    Write-Host "║  모드: $(if ($EnableParallel) { '병렬 설치 활성화' } else { '순차 설치' })                              ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($group in $global:ParallelInstallGroups) {
        # 이 그룹에서 설치할 도구 필터링
        $toolsInGroup = $group.Tools | Where-Object { $ToolsToInstall -contains $_ }
        
        if ($toolsInGroup.Count -eq 0) {
            continue
        }
        
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
        Write-Host "  📦 $($group.Name)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
        
        if ($EnableParallel -and $group.Parallel -and $toolsInGroup.Count -gt 1) {
            $results = Install-ToolsParallel -Tools $toolsInGroup -MaxConcurrent $MaxConcurrent
        } else {
            $results = Install-ToolsSequential -Tools $toolsInGroup
        }
        
        $totalResults.Success += $results.Success
        $totalResults.Failed += $results.Failed
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # 결과 요약
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           설치 완료 요약                              ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  ✅ 성공: $($totalResults.Success.Count)개                                        ║" -ForegroundColor Green
    Write-Host "║  ❌ 실패: $($totalResults.Failed.Count)개                                        ║" -ForegroundColor $(if ($totalResults.Failed.Count -gt 0) { 'Red' } else { 'Green' })
    Write-Host "║  ⏱️ 소요 시간: $($duration.ToString('mm\:ss'))                                 ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    return $totalResults
}

# ============================================
# 의존성 해결
# ============================================

<#
.SYNOPSIS
    도구의 의존성을 확인하고 설치 순서를 결정합니다.
.PARAMETER Tools
    설치할 도구 목록
.PARAMETER Dependencies
    의존성 정의 해시테이블
.OUTPUTS
    [string[]] 정렬된 설치 순서
#>
function Resolve-ToolDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Tools,
        
        [hashtable]$Dependencies = @{}
    )
    
    $resolved = @()
    $unresolved = @()
    
    function Resolve-DependencyRecursive {
        param([string]$Tool)
        
        if ($resolved -contains $Tool) {
            return
        }
        
        if ($unresolved -contains $Tool) {
            Write-Log "순환 의존성 감지: $Tool" -Level WARNING
            return
        }
        
        $unresolved += $Tool
        
        if ($Dependencies.ContainsKey($Tool)) {
            foreach ($dep in $Dependencies[$Tool]) {
                if ($Tools -contains $dep) {
                    Resolve-DependencyRecursive -Tool $dep
                }
            }
        }
        
        $unresolved = $unresolved | Where-Object { $_ -ne $Tool }
        $script:resolved += $Tool
    }
    
    foreach ($tool in $Tools) {
        Resolve-DependencyRecursive -Tool $tool
    }
    
    return $resolved
}

Write-Log "병렬 설치 모듈 로드 완료" -Level INFO
