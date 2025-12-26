# 🚀 Windows 풀스택 개발 환경 자동 설치 시스템

**원클릭으로 완성하는 Windows 개발 환경!**

Windows에서 풀스택 개발을 위한 모든 도구를 자동으로 설치하고 설정하는 PowerShell 기반 자동화 시스템입니다.

---

## ✨ 주요 기능

- 🎯 **원클릭 설치**: 하나의 명령으로 모든 개발 도구 자동 설치
- 🔧 **맞춤형 설치**: 프론트엔드, 백엔드, 풀스택 등 프로파일 선택 가능
- 📦 **패키지 관리**: Chocolatey + Winget 자동 설치 및 관리
- ✅ **설치 검증**: 설치 완료 후 자동으로 설치 상태 검증
- 💾 **백업/복원**: 기존 설정 백업 및 복원 기능
- 🎨 **설정 자동화**: VS Code, Git 등 최적화된 설정 자동 적용
- 📊 **상세 로깅**: 설치 과정 및 에러 로그 자동 기록

---

## 📋 설치 도구 목록

### 🛠️ 기본 개발 도구
- **Git** + GitHub CLI
- **nvm-windows** + **Node.js 22.12.0 (LTS)** + npm, yarn, pnpm
- **Python 3.x** + pip, pipx, Poetry
- **Java** (OpenJDK) + Maven, Gradle
- **Docker Desktop** + WSL2
- **Visual Studio Code** + 핵심 확장 팩
- **전자정부프레임워크 3.10** (선택 설치)

### 🗄️ 데이터베이스 (사용자 정의 설정)
- **PostgreSQL** (포트, 사용자명, 비밀번호 설정 가능)
- **MySQL** (포트, Root 사용자, 비밀번호 설정 가능)
- **MongoDB** (포트, 관리자 계정 설정 가능)
- **Redis** (포트, 비밀번호 설정 가능)
- SQLiteStudio

### 🎨 추가 도구
- **코드 품질**: Prettier, ESLint, Stylelint
- **터미널**: PowerShell 7, Windows Terminal, Oh My Posh
- **API 테스트**: Postman
- **DB 관리**: HeidiSQL
- **디자인**: Figma
- **편집기**: Notepad++
- **브라우저**: Google Chrome

---

## 🚀 빠른 시작

### 1️⃣ 사전 요구사항
- Windows 10 (1809+) 또는 Windows 11
- 관리자 권한
- 인터넷 연결

### 2️⃣ 설치 방법

#### PowerShell에서 실행 (관리자 권한)

```powershell
# 1. 저장소 클론
git clone https://github.com/YOUR_USERNAME/auto-init.git
cd auto-init

# 2. 실행 정책 설정 (한 번만)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. 설치 시작
.\setup.ps1
```

#### 또는 배치 파일로 실행

```batch
setup.bat
```

---

## 📖 사용 가이드

### 설치 모드 선택

실행 시 다음 옵션 중 선택 가능:

1. **빠른 설치 (풀스택 개발자)** - 모든 도구 설치
2. **프론트엔드 개발자** - Node.js, Git, VS Code 등
3. **백엔드 개발자** - Node.js, Python, Java, Docker, DB 등
4. **데이터 엔지니어** - Python, DB, Docker 등
5. **사용자 정의** - 원하는 도구만 선택 설치
6. **설치 검증만 실행** - 현재 설치 상태 확인

---

## 📂 프로젝트 구조

```
auto-init/
├── setup.ps1                    # 메인 설치 스크립트
├── README.md                    # 이 문서
│
├── config/                      # 각 도구별 설치 스크립트
│   ├── chocolatey.ps1          # Chocolatey 패키지 관리자
│   ├── winget.ps1              # Winget 설정
│   ├── git.ps1                 # Git + GitHub CLI
│   ├── node.ps1                # Node.js + npm/yarn/pnpm
│   ├── python.ps1              # Python + pip/pipx/poetry
│   ├── java.ps1                # Java + Maven/Gradle
│   ├── docker.ps1              # Docker + WSL2
│   ├── vscode.ps1              # VS Code + 확장
│   ├── database.ps1            # 데이터베이스 설치
│   ├── tools.ps1               # 추가 도구
│   └── linters.ps1             # Prettier, ESLint 등
│
├── scripts/                     # 유틸리티 스크립트
│   ├── utils.ps1               # 공통 함수
│   ├── validator.ps1           # 설치 검증
│   └── backup.ps1              # 백업/복원
│
├── assets/                      # 설정 템플릿
│   └── configs/
│       ├── settings.json       # VS Code 설정
│       ├── .gitconfig          # Git 설정
│       ├── .prettierrc.json    # Prettier 설정
│       └── .eslintrc.json      # ESLint 설정
│
├── data/                        # 데이터 저장
│   └── backup/                 # 백업 파일
│
└── logs/                        # 로그 파일
    ├── install.log             # 설치 로그
    ├── error.log               # 에러 로그
    └── validation_report.txt   # 검증 보고서
```

---

## 🔍 설치 검증

설치 완료 후 자동으로 검증이 실행되며, 수동으로도 실행 가능:

```powershell
.\scripts\validator.ps1
```

검증 결과는 테이블 형식으로 출력되며 `logs/validation_report.txt`에 저장됩니다.

---

## 💾 백업 및 복원

### 백업 실행

```powershell
.\scripts\backup.ps1
```

백업 항목:
- VS Code 설정 및 확장 목록
- Git 전역 설정
- PowerShell 프로필
- npm 설정

### 복원

백업 파일은 `data/backup/` 디렉토리에 저장되며, 타임스탬프별로 관리됩니다.

---

## ⚙️ VS Code 설정

자동으로 적용되는 주요 설정:

- **폰트**: Cascadia Code, JetBrains Mono
- **테마**: One Dark Pro + Material Icon Theme
- **포맷터**: Prettier (저장 시 자동 포맷)
- **린터**: ESLint (저장 시 자동 수정)
- **확장**: 60+ 필수 확장 자동 설치

---

## 🐛 문제 해결

### 실행 정책 오류

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 관리자 권한 필요

PowerShell을 관리자 권한으로 다시 실행하세요.

### Chocolatey 설치 실패

수동으로 설치:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### WSL2 설치 실패

Windows 기능에서 수동 활성화:
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

---

## 📝 로그 확인

- **설치 로그**: `logs/install.log`
- **에러 로그**: `logs/error.log`
- **검증 보고서**: `logs/validation_report.txt`

---

## 🤝 기여하기

개선 사항이나 버그 리포트는 Issues를 통해 제보해주세요!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

---

## 👨‍💻 만든 이

**Auto-Init Team**

---

## 🌟 유용한 링크

- [Chocolatey 패키지 검색](https://community.chocolatey.org/packages)
- [Winget 패키지 검색](https://winget.run/)
- [VS Code 확장 마켓플레이스](https://marketplace.visualstudio.com/)
- [Oh My Posh 테마](https://ohmyposh.dev/docs/themes)

---

## 📌 추가 정보

### 데이터베이스 설정

설치 시 각 데이터베이스의 포트, 사용자명, 비밀번호를 직접 설정할 수 있습니다.
설정 정보는 `logs/db_config.txt` 파일에 저장됩니다.

**기본 설정값:**
- PostgreSQL: 포트 5432, 사용자 postgres, 비밀번호 postgres
- MySQL: 포트 3306, 사용자 root, 비밀번호 root
- MongoDB: 포트 27017, 사용자 admin, 비밀번호 admin
- Redis: 포트 6379, 비밀번호 없음

### nvm 사용법

```powershell
# 다른 Node.js 버전 설치
nvm install 20.11.0

# 설치된 버전 목록 확인
nvm list

# 버전 전환
nvm use 20.11.0

# 현재 사용 중인 버전
nvm current
```

### 전자정부프레임워크 3.10

- 설치 경로: `C:\eGovFrameDev-3.10.0`
- Eclipse IDE 포함
- Tomcat 8.5 포함
- Maven 저장소 자동 설정
- 공식 문서: https://www.egovframe.go.kr

### Git 설정 추가

설치 후 Git 사용자 정보 설정:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### GitHub CLI 인증

```bash
gh auth login
```

### Oh My Posh 폰트 설치

```powershell
oh-my-posh font install
```

### Docker Desktop 초기 설정

설치 후 Docker Desktop을 실행하여 WSL2 통합 활성화

---

**🎉 즐거운 개발 되세요!**
