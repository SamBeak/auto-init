# ============================================
# 오프라인 설치용 캐시 매니저
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

# 캐시 디렉토리 설정
$global:CacheDir = Join-Path $PSScriptRoot "..\cache"
$global:CacheManifest = Join-Path $CacheDir "manifest.json"

# ============================================
# 캐시 디렉토리 초기화
# ============================================

function Initialize-CacheDirectory {
    $subDirs = @(
        "installers",      # 설치 파일
        "packages",        # Chocolatey/npm 패키지
        "extensions",      # VS Code 확장
        "configs"          # 설정 파일
    )
    
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
        Write-Log "캐시 디렉토리 생성: $CacheDir" -Level INFO
    }
    
    foreach ($subDir in $subDirs) {
        $path = Join-Path $CacheDir $subDir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    
    # 매니페스트 파일 초기화
    if (-not (Test-Path $CacheManifest)) {
        $manifest = @{
            CreatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Items = @()
        }
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $CacheManifest -Encoding UTF8
    }
    
    Write-Log "캐시 디렉토리 초기화 완료" -Level SUCCESS
}

# ============================================
# 다운로드 URL 정의
# ============================================

$global:DownloadSources = @{
    # 패키지 관리자
    Chocolatey = @{
        Name = "Chocolatey"
        Url = "https://community.chocolatey.org/install.ps1"
        Type = "script"
        FileName = "chocolatey-install.ps1"
    }
    
    # nvm-windows
    NvmWindows = @{
        Name = "nvm-windows"
        Url = "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe"
        Type = "installer"
        FileName = "nvm-setup.exe"
    }
    
    # Git
    Git = @{
        Name = "Git"
        Url = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
        Type = "installer"
        FileName = "Git-2.43.0-64-bit.exe"
    }
    
    # Python
    Python = @{
        Name = "Python"
        Url = "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe"
        Type = "installer"
        FileName = "python-3.12.1-amd64.exe"
    }
    
    # VS Code
    VSCode = @{
        Name = "VS Code"
        Url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        Type = "installer"
        FileName = "VSCodeSetup-x64.exe"
    }
    
    # OpenJDK 17
    OpenJDK = @{
        Name = "OpenJDK 17"
        Url = "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_windows-x64_bin.zip"
        Type = "archive"
        FileName = "openjdk-17.0.2_windows-x64_bin.zip"
    }
    
    # Docker Desktop
    DockerDesktop = @{
        Name = "Docker Desktop"
        Url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        Type = "installer"
        FileName = "Docker-Desktop-Installer.exe"
    }
    
    # PostgreSQL
    PostgreSQL = @{
        Name = "PostgreSQL"
        Url = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64.exe"
        Type = "installer"
        FileName = "postgresql-16.1-1-windows-x64.exe"
    }
    
    # Node.js LTS
    NodeJS = @{
        Name = "Node.js"
        Url = "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi"
        Type = "installer"
        FileName = "node-v22.12.0-x64.msi"
    }
    
    # Notepad++
    NotepadPlusPlus = @{
        Name = "Notepad++"
        Url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.2/npp.8.6.2.Installer.x64.exe"
        Type = "installer"
        FileName = "npp.8.6.2.Installer.x64.exe"
    }
    
    # Postman
    Postman = @{
        Name = "Postman"
        Url = "https://dl.pstmn.io/download/latest/win64"
        Type = "installer"
        FileName = "Postman-win64-Setup.exe"
    }
}

# ============================================
# VS Code 확장 목록
# ============================================

$global:VSCodeExtensions = @(
    "ms-python.python",
    "ms-python.vscode-pylance",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "eamodio.gitlens",
    "PKief.material-icon-theme",
    "ms-azuretools.vscode-docker",
    "ms-vscode-remote.remote-wsl"
)

# ============================================
# 캐시 다운로드 함수
# ============================================

function Save-ToCache {
    param(
        [string]$Url,
        [string]$FileName,
        [string]$Category = "installers"
    )
    
    $destPath = Join-Path $CacheDir $Category
    $filePath = Join-Path $destPath $FileName
    
    if (Test-Path $filePath) {
        Write-Log "$FileName 이미 캐시됨" -Level INFO
        return $filePath
    }
    
    try {
        Write-Log "$FileName 다운로드 중..." -Level INFO
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $filePath)
        
        $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
        Write-Log "$FileName 다운로드 완료 (${fileSize}MB)" -Level SUCCESS
        
        # 매니페스트 업데이트
        Update-CacheManifest -FileName $FileName -Category $Category -Size $fileSize
        
        return $filePath
    } catch {
        Write-Log "$FileName 다운로드 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Update-CacheManifest {
    param(
        [string]$FileName,
        [string]$Category,
        [double]$Size
    )
    
    $manifest = Get-Content $CacheManifest -Raw | ConvertFrom-Json
    
    $newItem = @{
        FileName = $FileName
        Category = $Category
        Size = $Size
        CachedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    # 기존 항목 제거 후 추가
    $manifest.Items = @($manifest.Items | Where-Object { $_.FileName -ne $FileName })
    $manifest.Items += $newItem
    $manifest.LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $CacheManifest -Encoding UTF8
}

# ============================================
# 전체 패키지 다운로드
# ============================================

function Start-FullCacheDownload {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              오프라인 설치 패키지 다운로드                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Initialize-CacheDirectory
    
    $totalItems = $DownloadSources.Count
    $currentItem = 0
    $successCount = 0
    $failCount = 0
    
    foreach ($key in $DownloadSources.Keys) {
        $source = $DownloadSources[$key]
        $currentItem++
        
        Write-Host ""
        Write-Host "[$currentItem/$totalItems] $($source.Name) 다운로드 중..." -ForegroundColor Yellow
        
        $category = switch ($source.Type) {
            "installer" { "installers" }
            "archive" { "installers" }
            "script" { "installers" }
            default { "installers" }
        }
        
        $result = Save-ToCache -Url $source.Url -FileName $source.FileName -Category $category
        
        if ($result) {
            $successCount++
        } else {
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  다운로드 완료: 성공 $successCount개, 실패 $failCount개" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  캐시 위치: $CacheDir" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Start-SelectiveCacheDownload {
    Write-Host ""
    Write-Host "다운로드할 패키지를 선택하세요:" -ForegroundColor Cyan
    Write-Host ""
    
    Initialize-CacheDirectory
    
    foreach ($key in $DownloadSources.Keys) {
        $source = $DownloadSources[$key]
        $cached = Test-Path (Join-Path $CacheDir "installers\$($source.FileName)")
        $status = if ($cached) { "[캐시됨]" } else { "" }
        
        $response = Read-Host "$($source.Name) $status 다운로드? (Y/N)"
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            Save-ToCache -Url $source.Url -FileName $source.FileName -Category "installers"
        }
    }
}

# ============================================
# 캐시 상태 확인
# ============================================

function Show-CacheStatus {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              캐시 상태                                        ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $CacheDir)) {
        Write-Host "  캐시 디렉토리가 없습니다. 다운로드를 먼저 실행하세요." -ForegroundColor Yellow
        return
    }
    
    $totalSize = 0
    
    foreach ($key in $DownloadSources.Keys) {
        $source = $DownloadSources[$key]
        $filePath = Join-Path $CacheDir "installers\$($source.FileName)"
        
        if (Test-Path $filePath) {
            $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
            $totalSize += $fileSize
            Write-Host "  ✅ " -ForegroundColor Green -NoNewline
            Write-Host "$($source.Name)" -NoNewline
            Write-Host " (${fileSize}MB)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ " -ForegroundColor Red -NoNewline
            Write-Host "$($source.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  총 캐시 크기: ${totalSize}MB" -ForegroundColor Cyan
    Write-Host "  캐시 위치: $CacheDir" -ForegroundColor Gray
    Write-Host ""
}

# ============================================
# 캐시 정리
# ============================================

function Clear-Cache {
    if (Test-Path $CacheDir) {
        $response = Read-Host "캐시를 모두 삭제하시겠습니까? (Y/N)"
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            Remove-Item -Path $CacheDir -Recurse -Force
            Write-Log "캐시 삭제 완료" -Level SUCCESS
        }
    } else {
        Write-Log "삭제할 캐시가 없습니다." -Level INFO
    }
}

# ============================================
# USB/외장 드라이브로 내보내기
# ============================================

function Export-CacheToExternal {
    param([string]$DestinationPath)
    
    if (-not (Test-Path $CacheDir)) {
        Write-Log "내보낼 캐시가 없습니다." -Level WARNING
        return
    }
    
    if (-not $DestinationPath) {
        $DestinationPath = Read-Host "내보낼 경로를 입력하세요 (예: E:\auto-init-cache)"
    }
    
    try {
        if (-not (Test-Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        }
        
        Write-Log "캐시 내보내기 중..." -Level INFO
        Copy-Item -Path "$CacheDir\*" -Destination $DestinationPath -Recurse -Force
        
        # 프로젝트 전체도 복사 (오프라인 설치용)
        $projectRoot = Split-Path $PSScriptRoot -Parent
        Copy-Item -Path $projectRoot -Destination $DestinationPath -Recurse -Force -Exclude "cache"
        
        Write-Log "내보내기 완료: $DestinationPath" -Level SUCCESS
    } catch {
        Write-Log "내보내기 실패: $($_.Exception.Message)" -Level ERROR
    }
}

# ============================================
# 메뉴
# ============================================

function Show-CacheMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    오프라인 캐시 매니저" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 전체 패키지 다운로드" -ForegroundColor White
    Write-Host "  [2] 선택적 다운로드" -ForegroundColor White
    Write-Host "  [3] 캐시 상태 확인" -ForegroundColor White
    Write-Host "  [4] 외부 드라이브로 내보내기" -ForegroundColor White
    Write-Host "  [5] 캐시 삭제" -ForegroundColor Red
    Write-Host "  [0] 종료" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Start-CacheManager {
    while ($true) {
        Show-CacheMenu
        $choice = Read-Host "선택 (0-5)"
        
        switch ($choice) {
            "1" { Start-FullCacheDownload }
            "2" { Start-SelectiveCacheDownload }
            "3" { Show-CacheStatus }
            "4" { Export-CacheToExternal }
            "5" { Clear-Cache }
            "0" { 
                Write-Log "캐시 매니저를 종료합니다." -Level INFO
                return 
            }
            default { Write-Log "잘못된 선택입니다." -Level WARNING }
        }
        
        Write-Host ""
        Read-Host "계속하려면 Enter를 누르세요..."
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    Start-CacheManager
}
