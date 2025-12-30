# Windows 개발 환경 자동 설치 테스트 가이드

## 🧪 테스트 방법

### 1. DRY-RUN 모드 (권장)
실제 설치를 하지 않고 시뮬레이션만 수행합니다.

```powershell
# 메인 메뉴에서 [F] 선택
# 또는 직접 실행
.\setup.ps1
# 메뉴에서 F 선택
```

### 2. 개별 스크립트 테스트
각 설치 스크립트를 독립적으로 테스트합니다.

```powershell
# 메인 메뉴에서 [G] 선택
# 또는 개별 스크립트 직접 실행
.\config\chocolatey.ps1  # Chocolatey만 테스트
.\config\node.ps1        # Node.js만 테스트
```

### 3. 환경 백업/복원
설치 전후 상태를 저장하고 복원합니다.

```powershell
# 환경 내보내기 (설치 전)
.\scripts\environment-manager.ps1
# 옵션 1 선택 (환경 내보내기)

# 환경 가져오기 (설치 후 복원)
.\scripts\environment-manager.ps1
# 옵션 2 선택 (환경 가져오기)
```

## 🐳 Docker 컨테이너 테스트

### Windows 컨테이너 사용

```powershell
# Windows Server Core 기반 컨테이너
docker run -it --name dev-test mcr.microsoft.com/windows/servercore:ltsc2022 powershell

# 컨테이너 안에서 프로젝트 복사 후 테스트
docker cp .\auto-init dev-test:C:\auto-init
```

### WSL에서 테스트

```bash
# WSL에서 PowerShell 실행
powershell.exe -File setup.ps1
```

## 🖥️ 가상 머신 테스트

### VirtualBox/VMware 사용
1. Windows 10/11 ISO 다운로드
2. 가상 머신 생성 (최소 4GB RAM, 50GB 저장공간)
3. 프로젝트 파일 복사 후 테스트
4. 스냅샷 생성으로 초기 상태 유지

### Hyper-V 사용

```powershell
# Hyper-V 가상 머신 생성
New-VM -Name "DevTestVM" -MemoryStartupBytes 4GB -VHDPath "C:\VMs\DevTestVM.vhdx"
```

## 🔄 반복 테스트 워크플로우

### 빠른 반복 테스트
1. **DRY-RUN**으로 로직 검증
2. **개별 스크립트 테스트**로 세부 기능 확인
3. **실제 설치** 전 환경 백업
4. 설치 후 **환경 복원**으로 초기화

### 권장 테스트 순서

```
DRY-RUN → 개별 스크립트 → 부분 설치 → 전체 설치 → 검증
```

## ⚠️ 주의사항

- **관리자 권한 필요**: 모든 설치 스크립트가 관리자 권한 필요
- **네트워크 연결**: 오프라인 모드 외에는 인터넷 연결 필수
- **충분한 저장공간**: 최소 20GB 여유 공간 확보
- **백업 권장**: 실제 설치 전 시스템 백업
