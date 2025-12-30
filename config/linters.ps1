# ============================================
# 코드 품질 도구 설치 (Prettier, ESLint 등)
# ============================================

. "$PSScriptRoot\..\scripts\utils.ps1"

function Install-Prettier {
    Write-Log "Prettier 전역 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "prettier") {
        $version = prettier --version
        Write-Log "Prettier가 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    if (-not (Test-ProgramInstalled -CommandCheck "npm")) {
        Write-Log "npm이 설치되어 있지 않습니다. Node.js를 먼저 설치하세요." -Level ERROR
        return $false
    }

    try {
        npm install -g prettier

        if ($LASTEXITCODE -eq 0) {
            $version = prettier --version
            Write-Log "Prettier 설치 완료: v$version" -Level SUCCESS
            return $true
        } else {
            Write-Log "Prettier 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "Prettier 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-ESLint {
    Write-Log "ESLint 전역 설치를 시작합니다..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "eslint") {
        $version = eslint --version
        Write-Log "ESLint가 이미 설치되어 있습니다: v$version" -Level SUCCESS
        return $true
    }

    if (-not (Test-ProgramInstalled -CommandCheck "npm")) {
        Write-Log "npm이 설치되어 있지 않습니다. Node.js를 먼저 설치하세요." -Level ERROR
        return $false
    }

    try {
        npm install -g eslint

        if ($LASTEXITCODE -eq 0) {
            $version = eslint --version
            Write-Log "ESLint 설치 완료: v$version" -Level SUCCESS
            return $true
        } else {
            Write-Log "ESLint 설치 실패" -Level ERROR
            return $false
        }

    } catch {
        Write-Log "ESLint 설치 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Create-PrettierConfig {
    Write-Log "Prettier 설정 파일 생성 중..." -Level INFO

    $configPath = Join-Path $PSScriptRoot "..\assets\configs\.prettierrc.json"
    $configDir = Split-Path $configPath -Parent

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (Test-Path $configPath) {
        Write-Log "Prettier 설정 파일이 이미 존재합니다." -Level INFO
        return $true
    }

    $prettierConfig = @{
        semi = $true
        singleQuote = $true
        tabWidth = 2
        trailingComma = "es5"
        printWidth = 80
        arrowParens = "always"
        endOfLine = "lf"
    } | ConvertTo-Json -Depth 10

    try {
        Set-Content -Path $configPath -Value $prettierConfig -Encoding UTF8
        Write-Log "Prettier 설정 파일 생성 완료: $configPath" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Prettier 설정 파일 생성 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Create-ESLintConfig {
    Write-Log "ESLint 설정 파일 생성 중..." -Level INFO

    $configPath = Join-Path $PSScriptRoot "..\assets\configs\.eslintrc.json"
    $configDir = Split-Path $configPath -Parent

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (Test-Path $configPath) {
        Write-Log "ESLint 설정 파일이 이미 존재합니다." -Level INFO
        return $true
    }

    $eslintConfig = @{
        env = @{
            browser = $true
            es2021 = $true
            node = $true
        }
        extends = @(
            "eslint:recommended"
        )
        parserOptions = @{
            ecmaVersion = "latest"
            sourceType = "module"
        }
        rules = @{
            indent = @("error", 2)
            "linebreak-style" = @("error", "unix")
            quotes = @("error", "single")
            semi = @("error", "always")
        }
    } | ConvertTo-Json -Depth 10

    try {
        Set-Content -Path $configPath -Value $eslintConfig -Encoding UTF8
        Write-Log "ESLint 설정 파일 생성 완료: $configPath" -Level SUCCESS
        return $true
    } catch {
        Write-Log "ESLint 설정 파일 생성 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Install-StylelintIfNeeded {
    Write-Log "Stylelint 설치 (CSS/SCSS 린터)..." -Level INFO

    if (Test-ProgramInstalled -CommandCheck "stylelint") {
        Write-Log "Stylelint가 이미 설치되어 있습니다." -Level SUCCESS
        return $true
    }

    try {
        npm install -g stylelint stylelint-config-standard

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Stylelint 설치 완료" -Level SUCCESS
            return $true
        }

    } catch {
        Write-Log "Stylelint 설치 중 오류: $($_.Exception.Message)" -Level WARNING
        return $false
    }
}

# 메인 실행
if ($MyInvocation.InvocationName -ne '.') {
    $prettierResult = Install-Prettier
    if ($prettierResult) { Add-InstallResult -ToolName "Prettier" -Status Success }
    else { Add-InstallResult -ToolName "Prettier" -Status Failed -Message "설치 실패" }
    
    $eslintResult = Install-ESLint
    if ($eslintResult) { Add-InstallResult -ToolName "ESLint" -Status Success }
    else { Add-InstallResult -ToolName "ESLint" -Status Failed -Message "설치 실패" }
    
    Create-PrettierConfig
    Create-ESLintConfig
    Install-StylelintIfNeeded
}
