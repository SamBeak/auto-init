# ============================================
# 프로젝트 템플릿 생성기
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 템플릿 정의
# ============================================

$global:ProjectTemplates = @{
    "react" = @{
        Name = "React (Vite)"
        Command = "npm create vite@latest {name} -- --template react-ts"
        Description = "React + TypeScript + Vite"
        PostInstall = @("cd {name}", "npm install")
    }
    "next" = @{
        Name = "Next.js"
        Command = "npx create-next-app@latest {name} --typescript --tailwind --eslint --app --src-dir"
        Description = "Next.js 14 + TypeScript + Tailwind CSS"
        PostInstall = @()
    }
    "vue" = @{
        Name = "Vue 3 (Vite)"
        Command = "npm create vite@latest {name} -- --template vue-ts"
        Description = "Vue 3 + TypeScript + Vite"
        PostInstall = @("cd {name}", "npm install")
    }
    "nuxt" = @{
        Name = "Nuxt 3"
        Command = "npx nuxi@latest init {name}"
        Description = "Nuxt 3 프레임워크"
        PostInstall = @("cd {name}", "npm install")
    }
    "express" = @{
        Name = "Express.js"
        Command = "npx express-generator-typescript {name}"
        Description = "Express + TypeScript 백엔드"
        PostInstall = @("cd {name}", "npm install")
    }
    "nest" = @{
        Name = "NestJS"
        Command = "npx @nestjs/cli new {name}"
        Description = "NestJS 프레임워크"
        PostInstall = @()
    }
    "fastapi" = @{
        Name = "FastAPI"
        Command = "mkdir {name} && cd {name} && python -m venv venv"
        Description = "FastAPI + Python"
        PostInstall = @("cd {name}", "venv\\Scripts\\activate", "pip install fastapi uvicorn")
        CreateFiles = @{
            "main.py" = @"
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
"@
            "requirements.txt" = @"
fastapi>=0.109.0
uvicorn>=0.27.0
"@
        }
    }
    "spring" = @{
        Name = "Spring Boot"
        Command = "curl https://start.spring.io/starter.zip -d type=maven-project -d language=java -d bootVersion=3.2.1 -d baseDir={name} -d groupId=com.example -d artifactId={name} -d name={name} -d packageName=com.example.{name} -d packaging=jar -d javaVersion=17 -d dependencies=web,devtools -o {name}.zip && tar -xf {name}.zip && del {name}.zip"
        Description = "Spring Boot 3 + Java 17"
        PostInstall = @()
    }
    "electron" = @{
        Name = "Electron + React"
        Command = "npx create-electron-vite {name} --template react-ts"
        Description = "Electron + React + TypeScript"
        PostInstall = @("cd {name}", "npm install")
    }
}

# ============================================
# 템플릿 선택 UI
# ============================================

function Show-TemplateMenu {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              프로젝트 템플릿 생성기                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "┌─ Frontend ────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│  [1] React (Vite)      - React + TypeScript + Vite            │" -ForegroundColor White
    Write-Host "│  [2] Next.js           - Next.js 14 + TypeScript + Tailwind   │" -ForegroundColor White
    Write-Host "│  [3] Vue 3 (Vite)      - Vue 3 + TypeScript + Vite            │" -ForegroundColor White
    Write-Host "│  [4] Nuxt 3            - Nuxt 3 프레임워크                    │" -ForegroundColor White
    Write-Host "└───────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
    Write-Host "┌─ Backend ─────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  [5] Express.js        - Express + TypeScript                 │" -ForegroundColor White
    Write-Host "│  [6] NestJS            - NestJS 프레임워크                    │" -ForegroundColor White
    Write-Host "│  [7] FastAPI           - FastAPI + Python                     │" -ForegroundColor White
    Write-Host "│  [8] Spring Boot       - Spring Boot 3 + Java 17              │" -ForegroundColor White
    Write-Host "└───────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "┌─ Desktop ─────────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│  [9] Electron + React  - Electron + React + TypeScript        │" -ForegroundColor White
    Write-Host "└───────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  [0] 돌아가기" -ForegroundColor Gray
    Write-Host ""
}

function Get-TemplateByChoice {
    param([string]$Choice)
    
    $templateMap = @{
        "1" = "react"
        "2" = "next"
        "3" = "vue"
        "4" = "nuxt"
        "5" = "express"
        "6" = "nest"
        "7" = "fastapi"
        "8" = "spring"
        "9" = "electron"
    }
    
    if ($templateMap.ContainsKey($Choice)) {
        return $templateMap[$Choice]
    }
    return $null
}

# ============================================
# 프로젝트 생성
# ============================================

function New-ProjectFromTemplate {
    param(
        [string]$TemplateKey,
        [string]$ProjectName,
        [string]$TargetPath = "."
    )
    
    $template = $ProjectTemplates[$TemplateKey]
    
    if (-not $template) {
        Write-Log "템플릿을 찾을 수 없습니다: $TemplateKey" -Level ERROR
        return $false
    }
    
    Write-Log "$($template.Name) 프로젝트 생성 중: $ProjectName" -Level INFO
    
    # 대상 디렉토리로 이동
    Push-Location $TargetPath
    
    try {
        # 명령어 실행
        $command = $template.Command -replace "\{name\}", $ProjectName
        Write-Log "실행: $command" -Level INFO
        Invoke-Expression $command
        
        # 추가 파일 생성 (있는 경우)
        if ($template.CreateFiles) {
            $projectPath = Join-Path $TargetPath $ProjectName
            foreach ($fileName in $template.CreateFiles.Keys) {
                $filePath = Join-Path $projectPath $fileName
                $template.CreateFiles[$fileName] | Set-Content -Path $filePath -Encoding UTF8
                Write-Log "파일 생성: $fileName" -Level SUCCESS
            }
        }
        
        # 후처리 명령 실행
        foreach ($postCmd in $template.PostInstall) {
            $cmd = $postCmd -replace "\{name\}", $ProjectName
            Write-Log "실행: $cmd" -Level INFO
            Invoke-Expression $cmd
        }
        
        Write-Log "프로젝트 생성 완료: $ProjectName" -Level SUCCESS
        Write-Host ""
        Write-Host "┌─────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "│  프로젝트 생성 완료!                            │" -ForegroundColor Green
        Write-Host "├─────────────────────────────────────────────────┤" -ForegroundColor Green
        Write-Host "│  cd $ProjectName" -ForegroundColor White -NoNewline
        Write-Host (" " * (46 - $ProjectName.Length)) -NoNewline
        Write-Host "│" -ForegroundColor Green
        Write-Host "│  npm run dev  (또는 해당 실행 명령)             │" -ForegroundColor White
        Write-Host "└─────────────────────────────────────────────────┘" -ForegroundColor Green
        Write-Host ""
        
        return $true
        
    } catch {
        Write-Log "프로젝트 생성 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    } finally {
        Pop-Location
    }
}

# ============================================
# 메인 실행
# ============================================

function Start-ProjectTemplateGenerator {
    while ($true) {
        Show-TemplateMenu
        $choice = Read-Host "템플릿 선택"
        
        if ($choice -eq "0") {
            return
        }
        
        $templateKey = Get-TemplateByChoice -Choice $choice
        
        if ($templateKey) {
            $projectName = Read-Host "프로젝트 이름"
            
            if ([string]::IsNullOrWhiteSpace($projectName)) {
                Write-Log "프로젝트 이름을 입력하세요." -Level WARNING
                continue
            }
            
            # 유효한 이름인지 확인
            if ($projectName -match '[<>:"/\\|?*]') {
                Write-Log "프로젝트 이름에 특수문자를 사용할 수 없습니다." -Level WARNING
                continue
            }
            
            $targetPath = Read-Host "생성 경로 (Enter = 현재 디렉토리)"
            if ([string]::IsNullOrWhiteSpace($targetPath)) {
                $targetPath = Get-Location
            }
            
            New-ProjectFromTemplate -TemplateKey $templateKey -ProjectName $projectName -TargetPath $targetPath
            
            $continue = Read-Host "다른 프로젝트를 생성하시겠습니까? (Y/N)"
            if ($continue -ne 'Y' -and $continue -ne 'y') {
                return
            }
        } else {
            Write-Log "잘못된 선택입니다." -Level WARNING
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-ProjectTemplateGenerator
}
