# 🚀 Windows 개발 환경 자동 설치 시스템

> **원클릭으로 완성하는 Windows 개발 환경!**  
> PowerShell 기반의 풀스택 개발 환경 자동화 도구

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📖 목차

- [주요 기능](#-주요-기능)
- [빠른 시작](#-빠른-시작)
- [설치 모드](#-설치-모드)
- [설치 도구 목록](#-설치-도구-목록)
- [오프라인 설치](#-오프라인-설치)
- [프로젝트 구조](#-프로젝트-구조)
- [사용법](#-사용법)
- [문제 해결](#-문제-해결)
- [기여하기](#-기여하기)

---

## ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| 🎯 **원클릭 설치** | 하나의 명령으로 모든 개발 도구 자동 설치 |
| 🔧 **맞춤형 프로파일** | 프론트엔드, 백엔드, 풀스택 등 역할별 선택 |
| � **실시간 진행률** | 설치 진행 상황 및 예상 시간 표시 |
| ✅ **자동 검증** | 설치 완료 후 상태 자동 검증 |
| � **결과 요약** | 성공/실패/건너뜀 항목 한눈에 확인 |
| � **에러 복구** | 설치 실패 시 자동 재시도 |
| 🏥 **헬스 체크** | 서비스 상태 모니터링 |
| 📴 **오프라인 설치** | 인터넷 없이 설치 가능 |
| 💾 **백업/복원** | 기존 설정 백업 및 복원 |

---

## 🚀 빠른 시작

### 사전 요구사항

- **OS**: Windows 10 (1809+) 또는 Windows 11
- **권한**: 관리자 권한
- **연결**: 인터넷 연결 (온라인 설치 시)

### 설치 실행

```powershell
# 1. 저장소 클론
git clone https://github.com/YOUR_USERNAME/auto-init.git
cd auto-init

# 2. setup.bat 더블클릭으로 실행 (권장)
```

### ⭐ 권장 실행 방법 (가장 간단)

**`setup.bat` 파일을 더블클릭하세요!**

- 자동으로 관리자 권한 요청 (UAC 프롬프트)
- 실행 정책 자동 설정
- 인코딩 문제 자동 해결

> ⚠️ **주의**: `setup.ps1`을 직접 더블클릭하면 실행되지 않습니다. 반드시 `setup.bat`을 사용하세요.

---

## 🎯 설치 모드

### 메인 메뉴

| 카테고리 | 옵션 | 설명 |
|----------|------|------|
| **설치 모드** | [1]-[5] | 프로필별 설치 |
| | [6] | 버전 선택 후 설치 |
| **도구** | [7] 설치 검증 | 설치 상태 확인 |
| | [8] 헬스 체크 | 서비스 상태 모니터링 |
| | [9] 도구 업데이트 | 설치된 도구 최신화 |
| | [A] 프로젝트 템플릿 | React, Next.js 등 보일러플레이트 생성 |
| **고급 기능** | [B] 오프라인 설치 | 캐시된 파일로 설치 |
| | [C] 캐시 다운로드 | 오프라인용 패키지 저장 |
| | [D] 환경 관리 | 환경 내보내기/가져오기/프로필 |
| | [E] 무인 설치 | config.json 기반 자동 설치 |

### 설치 프로필

| 모드 | 포함 도구 |
|------|-----------|
| **풀스택** | 모든 도구 (프론트엔드 + 백엔드 + DB) |
| **프론트엔드** | Git, Node.js, VS Code, 린터 |
| **백엔드** | Git, Node.js, Python, Java, Docker, DB |
| **데이터 엔지니어** | Python, Docker, DB, Apache Spark |
| **사용자 정의** | 원하는 도구만 선택 설치 |

---

## � 설치 도구 목록

### 기본 개발 도구

| 도구 | 버전 | 설명 |
|------|------|------|
| Git | Latest | GitHub CLI 포함 |
| Node.js | 22.12.0 LTS | nvm-windows + npm/yarn/pnpm |
| Python | 3.x | pip, pipx, Poetry |
| Java | OpenJDK 17 | Maven, Gradle |
| Docker | Desktop | WSL2 통합 |
| VS Code | Latest | 60+ 확장 자동 설치 |

### 데이터베이스

| DB | 기본 포트 | 기본 계정 |
|----|-----------|-----------|
| PostgreSQL | 5432 | postgres / postgres |
| MySQL | 3306 | root / root |
| MongoDB | 27017 | admin / admin |
| Redis | 6379 | - |

### 추가 도구

- **코드 품질**: Prettier, ESLint, Stylelint
- **터미널**: PowerShell 7, Windows Terminal, Oh My Posh
- **유틸리티**: Postman, HeidiSQL, Notepad++, Figma

---

## 📴 오프라인 설치

인터넷이 없는 환경에서도 설치 가능합니다.

### Step 1: 패키지 다운로드 (인터넷 환경)

```powershell
.\scripts\cache-manager.ps1
# → [1] 전체 패키지 다운로드 선택
```

### Step 2: 외부 드라이브로 내보내기

```powershell
# 캐시 매니저에서
# → [4] 외부 드라이브로 내보내기 선택
# → 경로 입력: E:\auto-init-offline
```

### Step 3: 오프라인 환경에서 설치

```powershell
# USB에서 복사 후
.\scripts\offline-install.ps1
```

**캐시 위치**: `auto-init/cache/installers/`

---

## 📂 프로젝트 구조

```
auto-init/
├── 📄 setup.ps1              # 메인 설치 스크립트
├── 📄 setup.bat              # 배치 런처
├── 📄 README.md
│
├── 📁 config/                # 도구별 설치 스크립트
│   ├── chocolatey.ps1
│   ├── winget.ps1
│   ├── git.ps1
│   ├── node.ps1
│   ├── python.ps1
│   ├── java.ps1
│   ├── docker.ps1
│   ├── vscode.ps1
│   ├── database.ps1
│   ├── tools.ps1
│   └── linters.ps1
│
├── 📁 scripts/               # 유틸리티 스크립트
│   ├── utils.ps1             # 공통 함수
│   ├── validator.ps1         # 설치 검증
│   ├── backup.ps1            # 백업/복원
│   ├── uninstall.ps1         # 제거 스크립트
│   ├── health-check.ps1      # 헬스 체크
│   ├── cache-manager.ps1     # 오프라인 캐시 관리
│   └── offline-install.ps1   # 오프라인 설치
│
├── 📁 assets/configs/        # 설정 템플릿
│   ├── settings.json
│   ├── .gitconfig
│   ├── .prettierrc.json
│   └── .eslintrc.json
│
├── 📁 cache/                 # 오프라인 캐시 (자동 생성)
├── 📁 data/backup/           # 백업 파일
└── 📁 logs/                  # 로그 파일
    ├── install.log
    ├── error.log
    └── validation_report.txt
```

---

## � 사용법

### 설치 검증

```powershell
.\scripts\validator.ps1
```

### 헬스 체크

```powershell
.\scripts\health-check.ps1
```

서비스 상태, 포트 연결, 환경 변수 등을 확인합니다.

### 백업/복원

```powershell
# 백업
.\scripts\backup.ps1

# 복원 - data/backup/ 디렉토리 참조
```

### 제거

```powershell
.\scripts\uninstall.ps1
```

---

## 🐛 문제 해결

<details>
<summary><b>실행 정책 오류</b></summary>

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```
</details>

<details>
<summary><b>관리자 권한 필요</b></summary>

PowerShell을 **관리자 권한**으로 다시 실행하세요.
</details>

<details>
<summary><b>Chocolatey 설치 실패</b></summary>

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```
</details>

<details>
<summary><b>WSL2 설치 실패</b></summary>

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
</details>

---

## 📝 설치 후 설정

### Git 사용자 정보

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### GitHub CLI 인증

```bash
gh auth login
```

### nvm 버전 관리

```powershell
nvm install 20.11.0    # 버전 설치
nvm list               # 설치 목록
nvm use 20.11.0        # 버전 전환
```

---

## 🤝 기여하기

1. Fork the Project
2. Create Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit Changes (`git commit -m 'Add AmazingFeature'`)
4. Push to Branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## � 유용한 링크

| 리소스 | 링크 |
|--------|------|
| Chocolatey 패키지 | https://community.chocolatey.org/packages |
| Winget 패키지 | https://winget.run |
| VS Code 확장 | https://marketplace.visualstudio.com |
| Oh My Posh 테마 | https://ohmyposh.dev/docs/themes |

---

## � 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

---

<div align="center">

**🎉 즐거운 개발 되세요!**

</div>
