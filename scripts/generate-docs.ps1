# ============================================
# 자동 문서 생성 스크립트
# Version: 1.0.0
# Description: PowerShell 스크립트에서 JSDoc 스타일 주석을 추출하여 마크다운 문서를 생성합니다.
# ============================================

param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\docs"),
    [switch]$IncludePrivate,
    [switch]$GenerateIndex
)

# ============================================
# 문서 생성 함수
# ============================================

<#
.SYNOPSIS
    PowerShell 스크립트 파일에서 함수 문서를 추출합니다.
.PARAMETER ScriptPath
    분석할 스크립트 파일 경로
.OUTPUTS
    [array] 함수 문서 객체 배열
#>
function Get-FunctionDocumentation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "파일을 찾을 수 없습니다: $ScriptPath" -ForegroundColor Red
        return @()
    }
    
    $content = Get-Content -Path $ScriptPath -Raw
    $functions = @()
    
    # 함수와 주석 블록 매칭
    $pattern = '(?s)<#(?<comment>.*?)#>\s*function\s+(?<name>[\w-]+)\s*\{(?<body>.*?)\n\}'
    $matches = [regex]::Matches($content, $pattern)
    
    foreach ($match in $matches) {
        $commentBlock = $match.Groups['comment'].Value
        $functionName = $match.Groups['name'].Value
        $functionBody = $match.Groups['body'].Value
        
        # 주석 파싱
        $doc = @{
            Name = $functionName
            Synopsis = ""
            Description = ""
            Parameters = @()
            Outputs = ""
            Examples = @()
            Notes = ""
            FilePath = $ScriptPath
            LineCount = ($functionBody -split "`n").Count
        }
        
        # .SYNOPSIS 추출
        if ($commentBlock -match '\.SYNOPSIS\s*\r?\n\s*(.+?)(?=\.|$)') {
            $doc.Synopsis = $Matches[1].Trim()
        }
        
        # .DESCRIPTION 추출
        if ($commentBlock -match '(?s)\.DESCRIPTION\s*\r?\n\s*(.+?)(?=\.[A-Z]|$)') {
            $doc.Description = $Matches[1].Trim()
        }
        
        # .PARAMETER 추출
        $paramMatches = [regex]::Matches($commentBlock, '\.PARAMETER\s+(\w+)\s*\r?\n\s*(.+?)(?=\.[A-Z]|$)')
        foreach ($pm in $paramMatches) {
            $doc.Parameters += @{
                Name = $pm.Groups[1].Value
                Description = $pm.Groups[2].Value.Trim()
            }
        }
        
        # .OUTPUTS 추출
        if ($commentBlock -match '\.OUTPUTS\s*\r?\n\s*(.+?)(?=\.[A-Z]|$)') {
            $doc.Outputs = $Matches[1].Trim()
        }
        
        # .EXAMPLE 추출
        $exampleMatches = [regex]::Matches($commentBlock, '(?s)\.EXAMPLE\s*\r?\n\s*(.+?)(?=\.[A-Z]|$)')
        foreach ($em in $exampleMatches) {
            $doc.Examples += $em.Groups[1].Value.Trim()
        }
        
        # .NOTES 추출
        if ($commentBlock -match '(?s)\.NOTES\s*\r?\n\s*(.+?)(?=\.[A-Z]|$)') {
            $doc.Notes = $Matches[1].Trim()
        }
        
        $functions += $doc
    }
    
    return $functions
}

<#
.SYNOPSIS
    함수 문서를 마크다운 형식으로 변환합니다.
.PARAMETER FunctionDoc
    함수 문서 객체
.OUTPUTS
    [string] 마크다운 문자열
#>
function ConvertTo-Markdown {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FunctionDoc
    )
    
    $md = @()
    
    # 함수 제목
    $md += "## $($FunctionDoc.Name)"
    $md += ""
    
    # Synopsis
    if ($FunctionDoc.Synopsis) {
        $md += "> $($FunctionDoc.Synopsis)"
        $md += ""
    }
    
    # Description
    if ($FunctionDoc.Description) {
        $md += "### 설명"
        $md += ""
        $md += $FunctionDoc.Description
        $md += ""
    }
    
    # Parameters
    if ($FunctionDoc.Parameters.Count -gt 0) {
        $md += "### 매개변수"
        $md += ""
        $md += "| 매개변수 | 설명 |"
        $md += "|----------|------|"
        
        foreach ($param in $FunctionDoc.Parameters) {
            $md += "| ``$($param.Name)`` | $($param.Description) |"
        }
        $md += ""
    }
    
    # Outputs
    if ($FunctionDoc.Outputs) {
        $md += "### 반환값"
        $md += ""
        $md += "``$($FunctionDoc.Outputs)``"
        $md += ""
    }
    
    # Examples
    if ($FunctionDoc.Examples.Count -gt 0) {
        $md += "### 예제"
        $md += ""
        
        $exampleNum = 1
        foreach ($example in $FunctionDoc.Examples) {
            $md += "**예제 $exampleNum**"
            $md += ""
            $md += '```powershell'
            $md += $example
            $md += '```'
            $md += ""
            $exampleNum++
        }
    }
    
    # Notes
    if ($FunctionDoc.Notes) {
        $md += "### 참고"
        $md += ""
        $md += $FunctionDoc.Notes
        $md += ""
    }
    
    $md += "---"
    $md += ""
    
    return $md -join "`n"
}

<#
.SYNOPSIS
    스크립트 파일의 문서를 생성합니다.
.PARAMETER ScriptPath
    스크립트 파일 경로
.PARAMETER OutputDir
    출력 디렉토리
#>
function New-ScriptDocumentation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )
    
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
    $functions = Get-FunctionDocumentation -ScriptPath $ScriptPath
    
    if ($functions.Count -eq 0) {
        Write-Host "  ⚠️ 문서화된 함수 없음: $scriptName" -ForegroundColor Yellow
        return $null
    }
    
    # 마크다운 생성
    $md = @()
    $md += "# $scriptName"
    $md += ""
    $md += "> 파일: ``$ScriptPath``"
    $md += ">"
    $md += "> 함수 수: $($functions.Count)"
    $md += ""
    $md += "## 목차"
    $md += ""
    
    foreach ($func in $functions) {
        $md += "- [$($func.Name)](#$($func.Name.ToLower()))"
    }
    
    $md += ""
    $md += "---"
    $md += ""
    
    foreach ($func in $functions) {
        $md += ConvertTo-Markdown -FunctionDoc $func
    }
    
    # 파일 저장
    $outputPath = Join-Path $OutputDir "$scriptName.md"
    $md -join "`n" | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Host "  ✅ 생성됨: $outputPath ($($functions.Count)개 함수)" -ForegroundColor Green
    
    return @{
        ScriptName = $scriptName
        FunctionCount = $functions.Count
        OutputPath = $outputPath
        Functions = $functions
    }
}

<#
.SYNOPSIS
    프로젝트 전체 문서를 생성합니다.
.PARAMETER ProjectRoot
    프로젝트 루트 경로
.PARAMETER OutputDir
    출력 디렉토리
#>
function New-ProjectDocumentation {
    param(
        [string]$ProjectRoot = (Join-Path $PSScriptRoot ".."),
        [string]$OutputDir = (Join-Path $PSScriptRoot "..\docs\api")
    )
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         📚 API 문서 자동 생성                         ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 출력 디렉토리 생성
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # 스크립트 파일 수집
    $scriptDirs = @(
        (Join-Path $ProjectRoot "scripts"),
        (Join-Path $ProjectRoot "config")
    )
    
    $allDocs = @()
    $totalFunctions = 0
    
    foreach ($dir in $scriptDirs) {
        if (Test-Path $dir) {
            Write-Host "📁 $dir" -ForegroundColor Cyan
            
            $scripts = Get-ChildItem -Path $dir -Filter "*.ps1"
            
            foreach ($script in $scripts) {
                $doc = New-ScriptDocumentation -ScriptPath $script.FullName -OutputDir $OutputDir
                if ($doc) {
                    $allDocs += $doc
                    $totalFunctions += $doc.FunctionCount
                }
            }
            
            Write-Host ""
        }
    }
    
    # 인덱스 파일 생성
    if ($GenerateIndex -or $true) {
        $indexPath = Join-Path $OutputDir "README.md"
        $index = @()
        
        $index += "# Auto-Init API 문서"
        $index += ""
        $index += "> 자동 생성된 API 문서"
        $index += ">"
        $index += "> 생성 시간: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $index += ">"
        $index += "> 총 함수 수: $totalFunctions"
        $index += ""
        $index += "## 모듈 목록"
        $index += ""
        $index += "| 모듈 | 함수 수 | 설명 |"
        $index += "|------|---------|------|"
        
        foreach ($doc in $allDocs | Sort-Object ScriptName) {
            $index += "| [$($doc.ScriptName)](./$($doc.ScriptName).md) | $($doc.FunctionCount) | - |"
        }
        
        $index += ""
        $index += "## 함수 색인"
        $index += ""
        
        $allFunctions = $allDocs | ForEach-Object { $_.Functions } | Sort-Object Name
        
        foreach ($func in $allFunctions) {
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($func.FilePath)
            $index += "- [$($func.Name)](./$scriptName.md#$($func.Name.ToLower())) - $($func.Synopsis)"
        }
        
        $index -join "`n" | Set-Content -Path $indexPath -Encoding UTF8
        Write-Host "📋 인덱스 생성됨: $indexPath" -ForegroundColor Green
    }
    
    # 요약
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         📊 문서 생성 완료                             ║" -ForegroundColor Cyan
    Write-Host "╠═══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  📄 생성된 문서: $($allDocs.Count)개                                    ║" -ForegroundColor White
    Write-Host "║  🔧 총 함수 수: $totalFunctions개                                     ║" -ForegroundColor White
    Write-Host "║  📁 출력 경로: $OutputDir" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    return @{
        DocumentCount = $allDocs.Count
        FunctionCount = $totalFunctions
        OutputDir = $OutputDir
    }
}

<#
.SYNOPSIS
    변경 로그 항목을 추가합니다.
.PARAMETER Version
    버전 번호
.PARAMETER Changes
    변경 사항 배열
.PARAMETER ChangelogPath
    변경 로그 파일 경로
#>
function Add-ChangelogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Changes,
        
        [string]$ChangelogPath = (Join-Path $PSScriptRoot "..\CHANGELOG.md")
    )
    
    $date = Get-Date -Format "yyyy-MM-dd"
    
    $entry = @()
    $entry += ""
    $entry += "## [$Version] - $date"
    $entry += ""
    
    foreach ($change in $Changes) {
        $entry += "- $change"
    }
    
    $entry += ""
    
    if (Test-Path $ChangelogPath) {
        $existingContent = Get-Content -Path $ChangelogPath -Raw
        
        # 헤더 다음에 새 항목 삽입
        if ($existingContent -match '(?s)(# Changelog.*?\n\n)(.*)') {
            $header = $Matches[1]
            $rest = $Matches[2]
            $newContent = $header + ($entry -join "`n") + "`n" + $rest
        } else {
            $newContent = $existingContent + "`n" + ($entry -join "`n")
        }
        
        Set-Content -Path $ChangelogPath -Value $newContent -Encoding UTF8
    } else {
        $content = @()
        $content += "# Changelog"
        $content += ""
        $content += "모든 주요 변경 사항이 이 파일에 기록됩니다."
        $content += ""
        $content += ($entry -join "`n")
        
        Set-Content -Path $ChangelogPath -Value ($content -join "`n") -Encoding UTF8
    }
    
    Write-Host "✅ 변경 로그 업데이트됨: $ChangelogPath" -ForegroundColor Green
}

# ============================================
# 메인 실행
# ============================================

if ($MyInvocation.InvocationName -ne '.') {
    New-ProjectDocumentation -OutputDir $OutputPath
}
