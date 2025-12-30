# ============================================
# Visual Studio Code 설치 및 설정
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"
. "$PSScriptRoot\chocolatey.ps1"

function Install-VSCode {
    Write-Log "Visual Studio Code 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "code") {
        $version = code --version | Select-Object -First 1
        Write-Log "VS Code가 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    # Chocolatey로 설치
    $result = Install-ChocolateyPackage -PackageName "vscode" -Params @("/NoDesktopIcon", "/NoQuicklaunchIcon", "/AddToPath")

    if ($result) {
        # 환경 변수 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $version = code --version | Select-Object -First 1
        Write-Log "VS Code 설치 완료: v$version" -Level SUCCESS
        return $true
    }

    return $false
}

function Install-VSCodeExtensions {
    Write-Log "VS Code 확장 설치를 시작합니다..." -Level INFO

    if (-not (Test-ProgramInstalled -CommandCheck "code")) {
        Write-Log "VS Code가 설치되어 있지 않습니다." -Level ERROR
        return $false
    }

    # 필수 확장 목록
    $extensions = @(
        # 언어 지원
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-vscode.cpptools",
        "golang.go",

        # 웹 개발
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "bradlc.vscode-tailwindcss",
        "dsznajder.es7-react-js-snippets",

        # 프레임워크
        "Vue.volar",
        "svelte.svelte-vscode",

        # 데이터베이스
        "mtxr.sqltools",
        "mongodb.mongodb-vscode",
		"postgresql.postgresql",

        # Git
        "eamodio.gitlens",
        "mhutchie.git-graph",

        # Docker
        "ms-azuretools.vscode-docker",

        # 유틸리티
        "christian-kohler.path-intellisense",
        "formulahendry.auto-rename-tag",
        "formulahendry.auto-close-tag",
        "naumovs.color-highlight",
        "PKief.material-icon-theme",
        "zhuangtongfa.material-theme",

        # 코드 품질
        "streetsidesoftware.code-spell-checker",
        "usernamehw.errorlens",
        "wayou.vscode-todo-highlight",

        # 원격 개발
        "ms-vscode-remote.remote-wsl",
        "ms-vscode-remote.remote-containers",

        # REST API
        "humao.rest-client",

        # Markdown
        "yzhang.markdown-all-in-one",

        # Live Server
        "ritwickdey.liveserver"
    )

    $successCount = 0
    $failCount = 0

    foreach ($extension in $extensions) {
        try {
            Write-Log "설치 중: $extension" -Level INFO
            code --install-extension $extension --force 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                Write-Log "$extension 설치 완료" -Level SUCCESS
                $successCount++
            } else {
                Write-Log "$extension 설치 실패" -Level WARNING
                $failCount++
            }

        } catch {
            Write-Log "$extension 설치 중 오류: $($_.Exception.Message)" -Level ERROR
            $failCount++
        }

        Start-Sleep -Milliseconds 500  # API 제한 방지
    }

    Write-Log "VS Code 확장 설치 완료 (성공: $successCount, 실패: $failCount)" -Level INFO
    return ($failCount -eq 0)
}

function Set-VSCodeSettings {
    Write-Log "VS Code 설정 구성 중..." -Level INFO

    $settingsPath = Join-Path $env:APPDATA "Code\User\settings.json"
    $settingsDir = Split-Path $settingsPath -Parent

    # 설정 디렉토리 생성
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # 템플릿 설정 파일 경로
    $templatePath = Join-Path $PSScriptRoot "..\assets\configs\settings.json"

    # 기존 설정 백업
    if (Test-Path $settingsPath) {
        Backup-Configuration -ConfigPath $settingsPath
    }

    # 템플릿 설정 복사 (템플릿이 있는 경우)
    if (Test-Path $templatePath) {
        try {
            Copy-Item -Path $templatePath -Destination $settingsPath -Force
            Write-Log "VS Code 설정 파일 적용 완료" -Level SUCCESS
            return $true
        } catch {
            Write-Log "설정 파일 복사 실패: $($_.Exception.Message)" -Level ERROR
            return $false
        }
    } else {
        Write-Log "템플릿 설정 파일을 찾을 수 없습니다: $templatePath" -Level WARNING

        # 기본 설정 생성
        $defaultSettings = @{
            "editor.fontSize" = 14
            "editor.tabSize" = 2
            "editor.formatOnSave" = $true
            "editor.defaultFormatter" = "esbenp.prettier-vscode"
            "editor.codeActionsOnSave" = @{
                "source.fixAll.eslint" = $true
            }
            "files.autoSave" = "afterDelay"
            "files.autoSaveDelay" = 1000
            "terminal.integrated.defaultProfile.windows" = "PowerShell"
            "workbench.iconTheme" = "material-icon-theme"
            "workbench.colorTheme" = "One Dark Pro"
        } | ConvertTo-Json -Depth 10

        Set-Content -Path $settingsPath -Value $defaultSettings -Encoding UTF8
        Write-Log "기본 VS Code 설정 파일 생성 완료" -Level SUCCESS
        return $true
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    $vscodeResult = Install-VSCode
    if ($vscodeResult) {
        Add-InstallResult -ToolName "VS Code" -Status Success
    } else {
        Add-InstallResult -ToolName "VS Code" -Status Failed -Message "설치 실패"
    }
    
    Install-VSCodeExtensions
    Set-VSCodeSettings
}
