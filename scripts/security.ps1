# ============================================
# 보안 관련 유틸리티 함수
# Version: 1.0.0
# ============================================

. "$PSScriptRoot\utils.ps1"

# ============================================
# 체크섬 검증
# ============================================

<#
.SYNOPSIS
    파일의 체크섬을 검증합니다.
.DESCRIPTION
    다운로드한 파일의 무결성을 SHA256, SHA512, MD5 등의 알고리즘으로 검증합니다.
.PARAMETER FilePath
    검증할 파일의 경로
.PARAMETER ExpectedHash
    예상되는 해시값
.PARAMETER Algorithm
    해시 알고리즘 (SHA256, SHA512, MD5)
.EXAMPLE
    Test-FileChecksum -FilePath "C:\Downloads\installer.exe" -ExpectedHash "abc123..." -Algorithm "SHA256"
.OUTPUTS
    [bool] 체크섬이 일치하면 $true, 아니면 $false
#>
function Test-FileChecksum {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpectedHash,
        
        [ValidateSet('SHA256', 'SHA512', 'MD5', 'SHA1')]
        [string]$Algorithm = 'SHA256'
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "파일을 찾을 수 없습니다: $FilePath" -Level ERROR
        return $false
    }
    
    try {
        Write-Log "체크섬 검증 중 ($Algorithm): $FilePath" -Level INFO
        
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash
        $isValid = $actualHash -eq $ExpectedHash.ToUpper()
        
        if ($isValid) {
            Write-Log "체크섬 검증 성공" -Level SUCCESS
        } else {
            Write-Log "체크섬 불일치! 예상: $ExpectedHash, 실제: $actualHash" -Level ERROR
        }
        
        return $isValid
        
    } catch {
        Write-Log "체크섬 검증 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    파일의 체크섬을 계산합니다.
.PARAMETER FilePath
    체크섬을 계산할 파일 경로
.PARAMETER Algorithm
    해시 알고리즘
.OUTPUTS
    [string] 계산된 해시값
#>
function Get-FileChecksumValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [ValidateSet('SHA256', 'SHA512', 'MD5', 'SHA1')]
        [string]$Algorithm = 'SHA256'
    )
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    try {
        return (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash
    } catch {
        return $null
    }
}

# ============================================
# Windows Credential Manager 연동
# ============================================

<#
.SYNOPSIS
    Windows Credential Manager에 자격 증명을 저장합니다.
.PARAMETER TargetName
    자격 증명의 고유 식별자
.PARAMETER Username
    사용자 이름
.PARAMETER Password
    비밀번호 (SecureString)
.EXAMPLE
    Save-SecureCredential -TargetName "AutoInit_PostgreSQL" -Username "postgres" -Password $securePassword
#>
function Save-SecureCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetName,
        
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $true)]
        [SecureString]$Password
    )
    
    try {
        # cmdkey를 사용하여 자격 증명 저장
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
        
        $result = cmdkey /add:$TargetName /user:$Username /pass:$plainPassword 2>&1
        
        # 메모리에서 평문 비밀번호 제거
        $plainPassword = $null
        [System.GC]::Collect()
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "자격 증명 저장 완료: $TargetName" -Level SUCCESS
            return $true
        } else {
            Write-Log "자격 증명 저장 실패: $result" -Level ERROR
            return $false
        }
        
    } catch {
        Write-Log "자격 증명 저장 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    Windows Credential Manager에서 자격 증명을 가져옵니다.
.PARAMETER TargetName
    자격 증명의 고유 식별자
.OUTPUTS
    [PSCredential] 자격 증명 객체
#>
function Get-SecureCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetName
    )
    
    try {
        # PowerShell 5.1+에서 사용 가능
        $credential = Get-StoredCredential -Target $TargetName -ErrorAction SilentlyContinue
        
        if ($credential) {
            return $credential
        }
        
        # 대체 방법: cmdkey로 확인
        $result = cmdkey /list:$TargetName 2>&1
        
        if ($result -like "*$TargetName*") {
            Write-Log "자격 증명 찾음: $TargetName (수동 입력 필요)" -Level INFO
            return $null
        }
        
        Write-Log "자격 증명을 찾을 수 없습니다: $TargetName" -Level WARNING
        return $null
        
    } catch {
        Write-Log "자격 증명 조회 중 오류: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    Windows Credential Manager에서 자격 증명을 삭제합니다.
.PARAMETER TargetName
    삭제할 자격 증명의 고유 식별자
#>
function Remove-SecureCredential {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetName
    )
    
    try {
        $result = cmdkey /delete:$TargetName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "자격 증명 삭제 완료: $TargetName" -Level SUCCESS
            return $true
        } else {
            Write-Log "자격 증명 삭제 실패: $result" -Level WARNING
            return $false
        }
        
    } catch {
        Write-Log "자격 증명 삭제 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    사용자로부터 안전하게 비밀번호를 입력받습니다.
.PARAMETER Prompt
    입력 프롬프트 메시지
.OUTPUTS
    [SecureString] 입력된 비밀번호
#>
function Read-SecurePassword {
    param(
        [string]$Prompt = "비밀번호를 입력하세요"
    )
    
    return Read-Host -Prompt $Prompt -AsSecureString
}

<#
.SYNOPSIS
    SecureString을 평문 문자열로 변환합니다. (내부 용도)
.PARAMETER SecureString
    변환할 SecureString
.OUTPUTS
    [string] 평문 문자열
#>
function ConvertFrom-SecureStringToPlain {
    param(
        [Parameter(Mandatory = $true)]
        [SecureString]$SecureString
    )
    
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

# ============================================
# 데이터베이스 자격 증명 관리
# ============================================

<#
.SYNOPSIS
    데이터베이스 자격 증명을 안전하게 저장합니다.
.PARAMETER DatabaseType
    데이터베이스 유형 (PostgreSQL, MySQL, MongoDB, Redis)
.PARAMETER Username
    사용자 이름
.PARAMETER Password
    비밀번호 (SecureString)
.PARAMETER Port
    포트 번호
#>
function Save-DatabaseCredential {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'MongoDB', 'Redis')]
        [string]$DatabaseType,
        
        [string]$Username,
        
        [SecureString]$Password,
        
        [int]$Port
    )
    
    $targetName = "AutoInit_$DatabaseType"
    
    # 자격 증명 저장
    if ($Password) {
        Save-SecureCredential -TargetName $targetName -Username $Username -Password $Password
    }
    
    # 포트 정보는 별도 저장 (환경 변수 또는 설정 파일)
    $configPath = Join-Path $PSScriptRoot "..\data\db-config.json"
    $configDir = Split-Path $configPath -Parent
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    $config = @{}
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
    }
    
    $config[$DatabaseType] = @{
        Port = $Port
        Username = $Username
        CredentialTarget = $targetName
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Log "$DatabaseType 설정 저장 완료" -Level SUCCESS
}

<#
.SYNOPSIS
    저장된 데이터베이스 자격 증명을 가져옵니다.
.PARAMETER DatabaseType
    데이터베이스 유형
.OUTPUTS
    [hashtable] 자격 증명 정보
#>
function Get-DatabaseCredential {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'MongoDB', 'Redis')]
        [string]$DatabaseType
    )
    
    $configPath = Join-Path $PSScriptRoot "..\data\db-config.json"
    
    if (-not (Test-Path $configPath)) {
        return $null
    }
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
        
        if ($config.ContainsKey($DatabaseType)) {
            return $config[$DatabaseType]
        }
        
        return $null
        
    } catch {
        Write-Log "데이터베이스 설정 로드 실패: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

# ============================================
# 설치 소스 검증
# ============================================

<#
.SYNOPSIS
    Chocolatey 패키지가 공식 패키지인지 확인합니다.
.PARAMETER PackageName
    패키지 이름
.OUTPUTS
    [bool] 공식 패키지 여부
#>
function Test-OfficialChocolateyPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )
    
    try {
        $packageInfo = choco info $PackageName --limit-output 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $packageInfo) {
            # community.chocolatey.org에서 제공하는 패키지인지 확인
            $searchResult = choco search $PackageName --exact --limit-output 2>&1
            
            if ($searchResult -like "*$PackageName*") {
                Write-Log "공식 Chocolatey 패키지 확인됨: $PackageName" -Level SUCCESS
                return $true
            }
        }
        
        Write-Log "패키지를 찾을 수 없거나 비공식 패키지입니다: $PackageName" -Level WARNING
        return $false
        
    } catch {
        Write-Log "패키지 확인 중 오류: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

# ============================================
# 보안 다운로드
# ============================================

<#
.SYNOPSIS
    HTTPS를 통해 파일을 안전하게 다운로드하고 체크섬을 검증합니다.
.PARAMETER Url
    다운로드 URL (HTTPS만 허용)
.PARAMETER OutputPath
    저장할 파일 경로
.PARAMETER ExpectedHash
    예상 체크섬 (선택)
.PARAMETER Algorithm
    체크섬 알고리즘
.OUTPUTS
    [bool] 다운로드 및 검증 성공 여부
#>
function Get-SecureDownload {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [string]$ExpectedHash = $null,
        
        [ValidateSet('SHA256', 'SHA512', 'MD5')]
        [string]$Algorithm = 'SHA256'
    )
    
    # HTTPS 확인
    if (-not $Url.StartsWith("https://")) {
        Write-Log "보안 경고: HTTPS URL만 허용됩니다. URL: $Url" -Level ERROR
        return $false
    }
    
    try {
        Write-Log "보안 다운로드 시작: $Url" -Level INFO
        
        # TLS 1.2 강제
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # 다운로드
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        
        Write-Log "다운로드 완료: $OutputPath" -Level SUCCESS
        
        # 체크섬 검증 (제공된 경우)
        if ($ExpectedHash) {
            $isValid = Test-FileChecksum -FilePath $OutputPath -ExpectedHash $ExpectedHash -Algorithm $Algorithm
            
            if (-not $isValid) {
                Write-Log "체크섬 검증 실패! 파일을 삭제합니다." -Level ERROR
                Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
                return $false
            }
        }
        
        return $true
        
    } catch {
        Write-Log "다운로드 실패: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

Write-Log "보안 모듈 로드 완료" -Level INFO
