# ============================================
# UX 개선 모듈
# Version: 1.0.0
# Description: 사용자 경험 향상을 위한 기능 모음
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 프로필 정보 로드
# ============================================

<#
.SYNOPSIS
    profiles.json 파일에서 프로필 정보를 로드합니다.
.OUTPUTS
    [PSCustomObject] 프로필 데이터
#>
function Get-ProfilesData {
    $profilesPath = Join-Path $PSScriptRoot "..\profiles.json"
    
    if (-not (Test-Path $profilesPath)) {
        Write-Log "profiles.json 파일을 찾을 수 없습니다." -Level WARNING
        return $null
    }
    
    try {
        $data = Get-Content -Path $profilesPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return $data
    } catch {
        Write-Log "프로필 데이터 로드 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    특정 프로필의 정보를 가져옵니다.
.PARAMETER ProfileKey
    프로필 키 (fullstack, frontend, backend, data-engineer)
.OUTPUTS
    [PSCustomObject] 프로필 정보
#>
function Get-ProfileInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileKey
    )
    
    $data = Get-ProfilesData
    if (-not $data) { return $null }
    
    $profileData = $data.profiles.$ProfileKey
    return $profileData
}

# ============================================
# 예상 시간/용량 계산
# ============================================

<#
.SYNOPSIS
    프로필의 예상 설치 시간을 계산합니다.
.PARAMETER ProfileKey
    프로필 키
.OUTPUTS
    [int] 예상 설치 시간 (분)
#>
function Get-EstimatedInstallTime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileKey
    )
    
    $profileData = Get-ProfileInfo -ProfileKey $ProfileKey
    if (-not $profileData) { return 30 }
    
    return $profileData.estimatedTime
}

<#
.SYNOPSIS
    프로필의 예상 디스크 사용량을 계산합니다.
.PARAMETER ProfileKey
    프로필 키
.OUTPUTS
    [hashtable] 예상 디스크 사용량 정보
#>
function Get-EstimatedDiskUsage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileKey
    )
    
    $profileData = Get-ProfileInfo -ProfileKey $ProfileKey
    if (-not $profileData) {
        return @{
            TotalGB = 10
            TotalMB = 10240
            ByCategory = @()
        }
    }
    
    $totalMB = 0
    $byCategory = @()
    
    foreach ($category in $profileData.categories) {
        $categoryTotal = 0
        foreach ($tool in $category.tools) {
            $categoryTotal += $tool.size
        }
        $totalMB += $categoryTotal
        $byCategory += @{
            Name = $category.name
            Icon = $category.icon
            SizeMB = $categoryTotal
        }
    }
    
    return @{
        TotalGB = [math]::Round($totalMB / 1024, 2)
        TotalMB = $totalMB
        ByCategory = $byCategory
    }
}

# ============================================
# 상세 설치 미리보기
# ============================================

<#
.SYNOPSIS
    설치 전 상세 미리보기를 표시합니다.
.PARAMETER ProfileKey
    프로필 키
.OUTPUTS
    [bool] 사용자 확인 결과
#>
function Show-DetailedInstallPreview {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileKey
    )
    
    $profileData = Get-ProfileInfo -ProfileKey $ProfileKey
    if (-not $profileData) {
        Write-Host "프로필 정보를 로드할 수 없습니다." -ForegroundColor Red
        return $false
    }
    
    $estimatedTime = Get-EstimatedInstallTime -ProfileKey $ProfileKey
    $diskUsage = Get-EstimatedDiskUsage -ProfileKey $ProfileKey
    
    # 현재 디스크 여유 공간 확인
    $drive = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                   ║" -ForegroundColor Cyan
    Write-Host "║  📋 " -ForegroundColor Cyan -NoNewline
    Write-Host "$($profileData.name)" -ForegroundColor Yellow -NoNewline
    Write-Host " 설치 미리보기" -ForegroundColor White -NoNewline
    $padding = 41 - $profileData.name.Length
    Write-Host (" " * $padding) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "║                                                                   ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # 설명
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "📝 $($profileData.description)" -ForegroundColor Gray -NoNewline
    $descPad = 64 - $profileData.description.Length
    if ($descPad -lt 0) { $descPad = 0 }
    Write-Host (" " * $descPad) -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    
    Write-Host "╟───────────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    
    # 예상 시간 및 용량
    Write-Host "║                                                                   ║" -ForegroundColor Cyan
    Write-Host "║  ⏱️  " -ForegroundColor Cyan -NoNewline
    Write-Host "예상 설치 시간: " -ForegroundColor White -NoNewline
    Write-Host "약 $estimatedTime 분" -ForegroundColor Green -NoNewline
    Write-Host "                                        ║" -ForegroundColor Cyan
    
    Write-Host "║  💾 " -ForegroundColor Cyan -NoNewline
    Write-Host "예상 디스크 사용량: " -ForegroundColor White -NoNewline
    Write-Host "약 $($diskUsage.TotalGB) GB" -ForegroundColor Green -NoNewline
    Write-Host "                                    ║" -ForegroundColor Cyan
    
    Write-Host "║  📁 " -ForegroundColor Cyan -NoNewline
    Write-Host "현재 여유 공간: " -ForegroundColor White -NoNewline
    $spaceColor = if ($freeSpaceGB -gt $diskUsage.TotalGB * 1.5) { "Green" } elseif ($freeSpaceGB -gt $diskUsage.TotalGB) { "Yellow" } else { "Red" }
    Write-Host "$freeSpaceGB GB" -ForegroundColor $spaceColor -NoNewline
    Write-Host "                                          ║" -ForegroundColor Cyan
    
    Write-Host "║                                                                   ║" -ForegroundColor Cyan
    Write-Host "╟───────────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  📦 설치 항목                                                     ║" -ForegroundColor Cyan
    Write-Host "╟───────────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    
    # 카테고리별 항목
    $totalTools = 0
    foreach ($category in $profileData.categories) {
        $catIcon = if ($category.icon) { $category.icon } else { "📦" }
        Write-Host "║  " -ForegroundColor Cyan -NoNewline
        Write-Host "$catIcon $($category.name)" -ForegroundColor Green -NoNewline
        $catPad = 62 - $category.name.Length
        Write-Host (" " * $catPad) -NoNewline
        Write-Host "║" -ForegroundColor Cyan
        
        foreach ($tool in $category.tools) {
            $requiredMark = if ($tool.required) { "●" } else { "○" }
            $sizeStr = if ($tool.size -ge 1024) { "$([math]::Round($tool.size / 1024, 1)) GB" } else { "$($tool.size) MB" }
            
            Write-Host "║     " -ForegroundColor Cyan -NoNewline
            Write-Host "$requiredMark " -ForegroundColor $(if ($tool.required) { "Yellow" } else { "DarkGray" }) -NoNewline
            Write-Host "$($tool.name)" -ForegroundColor White -NoNewline
            
            $toolPad = 45 - $tool.name.Length
            Write-Host (" " * $toolPad) -NoNewline
            Write-Host "$sizeStr" -ForegroundColor DarkGray -NoNewline
            
            $sizePad = 10 - $sizeStr.Length
            Write-Host (" " * $sizePad) -NoNewline
            Write-Host "║" -ForegroundColor Cyan
            
            $totalTools++
        }
        Write-Host "║                                                                   ║" -ForegroundColor Cyan
    }
    
    Write-Host "╟───────────────────────────────────────────────────────────────────╢" -ForegroundColor DarkCyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "총 $totalTools 개 항목  |  ● 필수  ○ 선택" -ForegroundColor Yellow -NoNewline
    Write-Host "                                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 디스크 공간 경고
    if ($freeSpaceGB -lt $diskUsage.TotalGB) {
        Write-Host "  ⚠️  경고: 디스크 공간이 부족할 수 있습니다!" -ForegroundColor Red
        Write-Host "       필요: $($diskUsage.TotalGB) GB, 여유: $freeSpaceGB GB" -ForegroundColor Red
        Write-Host ""
    }
    
    return Confirm-Action "이 항목들을 설치하시겠습니까?" -DefaultYes $true
}

# ============================================
# Windows 알림
# ============================================

<#
.SYNOPSIS
    Windows 토스트 알림을 표시합니다.
.PARAMETER Title
    알림 제목
.PARAMETER Message
    알림 메시지
.PARAMETER Type
    알림 유형 (Info, Success, Warning, Error)
#>
function Show-ToastNotification {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    try {
        # BurntToast 모듈 사용 시도
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast -ErrorAction SilentlyContinue
            
            $icon = switch ($Type) {
                'Success' { 'Completed' }
                'Warning' { 'Warning' }
                'Error' { 'Error' }
                default { 'Information' }
            }
            
            New-BurntToastNotification -Text $Title, $Message -AppLogo $null
            return
        }
        
        # Windows 기본 토스트 알림 (PowerShell 5.1+)
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
        $template = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$Title</text>
            <text id="2">$Message</text>
        </binding>
    </visual>
</toast>
"@
        
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("AutoInit")
        $notifier.Show($toast)
        
    } catch {
        # 토스트 알림 실패 시 콘솔에 출력
        $color = switch ($Type) {
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            default { 'Cyan' }
        }
        
        Write-Host ""
        Write-Host "  ┌────────────────────────────────────────┐" -ForegroundColor $color
        Write-Host "  │ 🔔 $Title" -ForegroundColor $color
        Write-Host "  │    $Message" -ForegroundColor White
        Write-Host "  └────────────────────────────────────────┘" -ForegroundColor $color
        Write-Host ""
    }
}

<#
.SYNOPSIS
    설치 완료 알림을 표시합니다.
.PARAMETER SuccessCount
    성공한 설치 수
.PARAMETER FailedCount
    실패한 설치 수
.PARAMETER Duration
    소요 시간
#>
function Show-InstallCompleteNotification {
    param(
        [int]$SuccessCount,
        [int]$FailedCount,
        [TimeSpan]$Duration
    )
    
    $durationStr = $Duration.ToString('hh\:mm\:ss')
    
    if ($FailedCount -eq 0) {
        Show-ToastNotification -Title "✅ 설치 완료!" -Message "모든 도구가 성공적으로 설치되었습니다. (소요시간: $durationStr)" -Type Success
    } else {
        Show-ToastNotification -Title "⚠️ 설치 완료 (일부 실패)" -Message "성공: $SuccessCount, 실패: $FailedCount (소요시간: $durationStr)" -Type Warning
    }
}

# ============================================
# 사운드 알림
# ============================================

<#
.SYNOPSIS
    시스템 사운드를 재생합니다.
.PARAMETER SoundType
    사운드 유형
#>
function Start-NotificationSound {
    param(
        [ValidateSet('Success', 'Warning', 'Error', 'Notification')]
        [string]$SoundType = 'Notification'
    )
    
    try {
        $sound = switch ($SoundType) {
            'Success' { [System.Media.SystemSounds]::Asterisk }
            'Warning' { [System.Media.SystemSounds]::Exclamation }
            'Error' { [System.Media.SystemSounds]::Hand }
            default { [System.Media.SystemSounds]::Beep }
        }
        
        $sound.Play()
    } catch {
        # 사운드 재생 실패 시 무시
    }
}

# ============================================
# 진행률 표시 개선
# ============================================

<#
.SYNOPSIS
    향상된 진행률 바를 표시합니다.
.PARAMETER Activity
    현재 작업 이름
.PARAMETER Status
    상태 메시지
.PARAMETER PercentComplete
    진행률 (0-100)
.PARAMETER EstimatedSecondsRemaining
    예상 남은 시간 (초)
#>
function Show-EnhancedProgress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [int]$EstimatedSecondsRemaining = -1
    )
    
    $width = 40
    $filled = [math]::Round($width * $PercentComplete / 100)
    $empty = $width - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    $timeStr = ""
    if ($EstimatedSecondsRemaining -gt 0) {
        $minutes = [math]::Floor($EstimatedSecondsRemaining / 60)
        $seconds = $EstimatedSecondsRemaining % 60
        $timeStr = " | 예상 남은 시간: ${minutes}분 ${seconds}초"
    }
    
    Write-Host "`r  [$bar] $PercentComplete%$timeStr  " -NoNewline -ForegroundColor Cyan
    
    # 표준 진행률 표시줄도 업데이트
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

# ============================================
# 대화형 도구 선택
# ============================================

<#
.SYNOPSIS
    체크박스 스타일로 도구를 선택할 수 있게 합니다.
.PARAMETER Tools
    선택 가능한 도구 목록
.PARAMETER DefaultSelected
    기본 선택된 도구 목록
.OUTPUTS
    [string[]] 선택된 도구 목록
#>
function Show-ToolSelector {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Tools,
        
        [string[]]$DefaultSelected = @()
    )
    
    $selected = @{}
    foreach ($tool in $Tools) {
        $selected[$tool.id] = $DefaultSelected -contains $tool.id -or $tool.required
    }
    
    $currentIndex = 0
    $done = $false
    
    while (-not $done) {
        Clear-Host
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║  도구 선택 (Space: 선택/해제, Enter: 확인)        ║" -ForegroundColor Cyan
        Write-Host "  ╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        for ($i = 0; $i -lt $Tools.Count; $i++) {
            $tool = $Tools[$i]
            $isSelected = $selected[$tool.id]
            $isCurrent = $i -eq $currentIndex
            
            $prefix = if ($isCurrent) { " ▶ " } else { "   " }
            $checkbox = if ($isSelected) { "[✓]" } else { "[ ]" }
            $requiredMark = if ($tool.required) { " (필수)" } else { "" }
            
            $color = if ($isCurrent) { "Yellow" } elseif ($isSelected) { "Green" } else { "Gray" }
            
            Write-Host "$prefix$checkbox $($tool.name)$requiredMark" -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "  ↑↓: 이동 | Space: 선택 | Enter: 확인 | Esc: 취소" -ForegroundColor DarkGray
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up
                if ($currentIndex -gt 0) { $currentIndex-- }
            }
            40 { # Down
                if ($currentIndex -lt $Tools.Count - 1) { $currentIndex++ }
            }
            32 { # Space
                $tool = $Tools[$currentIndex]
                if (-not $tool.required) {
                    $selected[$tool.id] = -not $selected[$tool.id]
                }
            }
            13 { # Enter
                $done = $true
            }
            27 { # Escape
                return @()
            }
        }
    }
    
    return $selected.Keys | Where-Object { $selected[$_] }
}

# ============================================
# 설치 타임라인
# ============================================

<#
.SYNOPSIS
    설치 과정을 타임라인 형식으로 표시합니다.
.PARAMETER Steps
    설치 단계 배열
.PARAMETER CurrentStep
    현재 단계 인덱스
#>
function Show-InstallTimeline {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Steps,
        
        [int]$CurrentStep = 0
    )
    
    Write-Host ""
    
    for ($i = 0; $i -lt $Steps.Count; $i++) {
        $step = $Steps[$i]
        $status = if ($i -lt $CurrentStep) { "completed" } elseif ($i -eq $CurrentStep) { "current" } else { "pending" }
        
        $icon = switch ($status) {
            "completed" { "✅" }
            "current" { "🔄" }
            "pending" { "⏳" }
        }
        
        $color = switch ($status) {
            "completed" { "Green" }
            "current" { "Yellow" }
            "pending" { "DarkGray" }
        }
        
        $connector = if ($i -lt $Steps.Count - 1) { "│" } else { " " }
        
        Write-Host "  $icon $step" -ForegroundColor $color
        if ($i -lt $Steps.Count - 1) {
            Write-Host "  $connector" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
}

Write-Log "UX 개선 모듈 로드 완료" -Level INFO
