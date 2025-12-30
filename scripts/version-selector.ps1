# ============================================
# 버전 선택 UI 스크립트
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 버전 정보 정의
# ============================================

$global:AvailableVersions = @{
    NodeJS = @{
        LTS = @("22.12.0", "20.11.0", "18.19.0")
        Current = @("23.4.0", "22.12.0")
        Description = "Node.js 런타임"
    }
    Python = @{
        Versions = @("3.12", "3.11", "3.10", "3.9")
        Description = "Python 인터프리터"
    }
    Java = @{
        Versions = @("21", "17", "11", "8")
        Description = "OpenJDK"
    }
    PostgreSQL = @{
        Versions = @("16", "15", "14", "13")
        Description = "PostgreSQL 데이터베이스"
    }
    MySQL = @{
        Versions = @("8.0", "5.7")
        Description = "MySQL 데이터베이스"
    }
}

# ============================================
# 버전 선택 UI
# ============================================

function Show-VersionSelector {
    param(
        [string]$ToolName,
        [string[]]$Versions,
        [string]$DefaultVersion = $null
    )
    
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  $ToolName 버전 선택" -ForegroundColor Cyan -NoNewline
    Write-Host (" " * (46 - $ToolName.Length)) -NoNewline
    Write-Host "│" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $Versions.Count; $i++) {
        $version = $Versions[$i]
        $marker = if ($version -eq $DefaultVersion) { "(권장)" } else { "" }
        
        if ($version -eq $DefaultVersion) {
            Write-Host "  [$($i + 1)] $version $marker" -ForegroundColor Green
        } else {
            Write-Host "  [$($i + 1)] $version $marker" -ForegroundColor White
        }
    }
    
    Write-Host "  [0] 건너뛰기" -ForegroundColor Yellow
    Write-Host ""
    
    $choice = Read-Host "선택 (Enter = 권장 버전)"
    
    if ([string]::IsNullOrEmpty($choice)) {
        return $DefaultVersion
    }
    
    if ($choice -eq "0") {
        return $null
    }
    
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $Versions.Count) {
        return $Versions[$index]
    }
    
    return $DefaultVersion
}

function Get-NodeJSVersionChoice {
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  Node.js 버전 유형 선택                         │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] LTS (Long Term Support) - 안정적, 권장" -ForegroundColor Green
    Write-Host "  [2] Current - 최신 기능" -ForegroundColor Yellow
    Write-Host "  [3] 특정 버전 직접 입력" -ForegroundColor White
    Write-Host "  [0] 건너뛰기" -ForegroundColor Gray
    Write-Host ""
    
    $typeChoice = Read-Host "선택 (Enter = LTS)"
    
    switch ($typeChoice) {
        "1" { return Show-VersionSelector -ToolName "Node.js LTS" -Versions $AvailableVersions.NodeJS.LTS -DefaultVersion "22.12.0" }
        "2" { return Show-VersionSelector -ToolName "Node.js Current" -Versions $AvailableVersions.NodeJS.Current -DefaultVersion "23.4.0" }
        "3" {
            $customVersion = Read-Host "버전 입력 (예: 20.10.0)"
            return $customVersion
        }
        "0" { return $null }
        default { return "22.12.0" }
    }
}

function Get-PythonVersionChoice {
    return Show-VersionSelector -ToolName "Python" -Versions $AvailableVersions.Python.Versions -DefaultVersion "3.12"
}

function Get-JavaVersionChoice {
    return Show-VersionSelector -ToolName "Java (OpenJDK)" -Versions $AvailableVersions.Java.Versions -DefaultVersion "17"
}

# ============================================
# 전체 버전 선택 메뉴
# ============================================

function Start-VersionSelection {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              개발 도구 버전 선택                              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "각 도구의 설치 버전을 선택하세요." -ForegroundColor Yellow
    Write-Host "Enter를 누르면 권장 버전이 선택됩니다." -ForegroundColor Gray
    Write-Host ""
    
    $selections = @{}
    
    # Node.js
    $nodeVersion = Get-NodeJSVersionChoice
    if ($nodeVersion) {
        $selections.NodeJS = $nodeVersion
        Write-Log "Node.js 버전 선택: $nodeVersion" -Level INFO
    }
    
    # Python
    $pythonVersion = Get-PythonVersionChoice
    if ($pythonVersion) {
        $selections.Python = $pythonVersion
        Write-Log "Python 버전 선택: $pythonVersion" -Level INFO
    }
    
    # Java
    $javaVersion = Get-JavaVersionChoice
    if ($javaVersion) {
        $selections.Java = $javaVersion
        Write-Log "Java 버전 선택: $javaVersion" -Level INFO
    }
    
    # 선택 요약
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│  선택된 버전 요약                               │" -ForegroundColor Green
    Write-Host "├─────────────────────────────────────────────────┤" -ForegroundColor Green
    
    foreach ($key in $selections.Keys) {
        $value = $selections[$key]
        Write-Host "│  $key : $value" -ForegroundColor White -NoNewline
        Write-Host (" " * (45 - $key.Length - $value.Length)) -NoNewline
        Write-Host "│" -ForegroundColor Green
    }
    
    Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
    
    return $selections
}

# ============================================
# 내보내기
# ============================================

function Export-VersionSelections {
    param(
        [hashtable]$Selections,
        [string]$OutputPath = ""
    )
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path $PSScriptRoot "..\version-selections.json"
    }
    
    $Selections | ConvertTo-Json | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Log "버전 선택 저장됨: $OutputPath" -Level SUCCESS
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    $selections = Start-VersionSelection
    
    $save = Read-Host "선택한 버전을 저장하시겠습니까? (Y/N)"
    if ($save -eq 'Y' -or $save -eq 'y') {
        Export-VersionSelections -Selections $selections
    }
}
