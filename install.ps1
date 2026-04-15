# =============================================================================
# install.ps1 - Agentic Coding Guide 설치 스크립트 (Kiro)
#
# 사용법:
#   .\install.ps1 [옵션] [프로젝트_경로]
#
# 옵션:
#   -DryRun        실제 복사 없이 미리보기
#   -Force         기존 파일 백업 없이 덮어쓰기
#   -Help          도움말 표시
#   -ShowVersion   버전 표시
#
# 프로젝트 경로를 생략하면 ~/Documents/builders-program-0416 을 대상으로 함
# =============================================================================

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Help,
    [switch]$ShowVersion,
    [Parameter(Position = 0)]
    [string]$ProjectPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:AppVersion = "2.2.0"

# --- 색상 출력 헬퍼 ---------------------------------------------------------

function Write-Info    { param([string]$Msg) Write-Host "  [정보] $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "  [완료] $Msg" -ForegroundColor Green }
function Write-Skip    { param([string]$Msg) Write-Host "  [건너뜀] $Msg" -ForegroundColor DarkGray }
function Write-Warn    { param([string]$Msg) Write-Host "  [경고] $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "  [오류] $Msg" -ForegroundColor Red }
function Write-Dry     { param([string]$Msg) Write-Host "  [미리보기] $Msg" -ForegroundColor Cyan }

function Write-Fatal {
    param([string]$Msg)
    Write-Err $Msg
    exit 1
}

# --- 전역 상태 --------------------------------------------------------------

$script:ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:TargetDir    = ""

# 결과 카운터
$script:CountCopied    = 0
$script:CountBackedUp  = 0
$script:CountSkipped   = 0
$script:CountProtected = 0
$script:CountDirCreated = 0

# 보호 파일 목록 (사용자 데이터가 축적되므로 덮어쓰지 않음)
$script:ProtectedFiles = @("learnings.md")

# --- 도움말 -----------------------------------------------------------------

function Show-Help {
    Write-Host @"

Agentic Coding Guide Installer v$($script:AppVersion)

Usage:
  .\install.ps1 [OPTIONS] [PROJECT_PATH]

OPTIONS:
  -DryRun        Preview what would be done without making changes
  -Force         Overwrite existing files without backup
  -Help          Show this help message
  -ShowVersion   Show version

ARGUMENTS:
  PROJECT_PATH   Target project directory (default: ~/Documents/builders-program-0416)

CONFLICT HANDLING:
  - Default: backs up existing files as .backup, then replaces with new version
  - -Force: overwrites without backup
  - Identical content: auto-skipped (idempotent)
  - learnings.md: NEVER overwritten (protected; accumulates user data)

EXAMPLES:
  # Install into default directory (~/Documents/builders-program-0416)
  .\install.ps1

  # Install into a specific project
  .\install.ps1 C:\projects\my-app

  # Preview only (no file changes)
  .\install.ps1 -DryRun

  # Overwrite without backup
  .\install.ps1 -Force C:\projects\my-app

FILES INSTALLED:
  .kiro\steering\boundaries.md
  .kiro\steering\conventions.md
  .kiro\steering\self-review.md
  .kiro\steering\learnings.md     (protected: never overwrites existing)
  .kiro\hooks\post-task-review.kiro.hook
  .kiro\hooks\periodic-review.kiro.hook
"@
}

# --- 보호 파일 확인 ---------------------------------------------------------

function Test-Protected {
    param([string]$FilePath)
    $fileName = Split-Path -Leaf $FilePath
    return $script:ProtectedFiles -contains $fileName
}

# --- 파일 내용 비교 ---------------------------------------------------------

function Test-FilesIdentical {
    param([string]$Path1, [string]$Path2)

    if (-not (Test-Path $Path1) -or -not (Test-Path $Path2)) {
        return $false
    }

    $hash1 = (Get-FileHash -Path $Path1 -Algorithm SHA256).Hash
    $hash2 = (Get-FileHash -Path $Path2 -Algorithm SHA256).Hash
    return $hash1 -eq $hash2
}

# --- 소스 파일 검증 ---------------------------------------------------------

function Test-SourceFiles {
    $missing = @()
    $kiroFiles = @(
        "kiro\steering\boundaries.md",
        "kiro\steering\conventions.md",
        "kiro\steering\learnings.md",
        "kiro\steering\self-review.md",
        "kiro\steering\fswrite-rule.md",
        "kiro\steering\builders-use-uv.md",
        "kiro\hooks\post-task-review.kiro.hook",
        "kiro\hooks\periodic-review.kiro.hook"
    )
    foreach ($f in $kiroFiles) {
        $fullPath = Join-Path $script:ScriptDir $f
        if (-not (Test-Path $fullPath)) {
            $missing += $f
        }
    }

    if ($missing.Count -gt 0) {
        Write-Err "소스 파일이 누락되었습니다:"
        foreach ($f in $missing) {
            Write-Err "  - $f"
        }
        Write-Fatal "저장소가 올바르게 클론되었는지 확인하세요."
    }
}

# --- 대상 디렉토리 검증 -----------------------------------------------------

function Resolve-TargetDir {
    param([string]$Path)

    $resolved = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Fatal "경로를 찾을 수 없습니다: $Path"
    }

    $dirPath = $resolved.Path
    if (-not (Test-Path $dirPath -PathType Container)) {
        Write-Fatal "디렉토리가 존재하지 않습니다: $dirPath"
    }

    # 쓰기 권한 테스트
    try {
        $testFile = Join-Path $dirPath ".install_write_test_$(Get-Random)"
        [IO.File]::WriteAllText($testFile, "test")
        Remove-Item $testFile -Force
    }
    catch {
        Write-Fatal "쓰기 권한이 없습니다: $dirPath"
    }

    $script:TargetDir = $dirPath
}

# --- 자기 자신에게 설치 방지 -------------------------------------------------

function Test-SelfInstall {
    $realScript = (Resolve-Path $script:ScriptDir).Path.TrimEnd('\', '/')
    $realTarget = (Resolve-Path $script:TargetDir).Path.TrimEnd('\', '/')

    if ($realScript -eq $realTarget) {
        Write-Err "이 저장소 자체에는 설치할 수 없습니다."
        Write-Err "대상 프로젝트 경로를 인자로 전달하세요."
        Write-Host ""
        Write-Host "    예: .\install.ps1 C:\path\to\my-project"
        exit 1
    }
}

# --- 프로젝트 디렉토리 휴리스틱 확인 ----------------------------------------

function Test-ProjectIndicators {
    $markers = @(".git", "package.json", "pyproject.toml", "Cargo.toml",
                 "go.mod", "pom.xml", "build.gradle", "Makefile", ".gitignore")
    $found = 0
    foreach ($m in $markers) {
        if (Test-Path (Join-Path $script:TargetDir $m)) {
            $found++
        }
    }

    if ($found -eq 0) {
        Write-Warn "프로젝트 파일이 감지되지 않았습니다: $($script:TargetDir)"
        Write-Warn "프로젝트 루트 디렉토리가 맞는지 확인하세요."
        if (-not $DryRun -and -not $Force) {
            Write-Host ""
            $answer = Read-Host "  계속 진행하시겠습니까? (y/N)"
            if ($answer -notmatch '^[yY]$') {
                Write-Info "설치를 취소합니다."
                exit 0
            }
        }
    }
}

# --- 디스크 공간 확인 -------------------------------------------------------

function Test-DiskSpace {
    try {
        $drive = (Get-Item $script:TargetDir).PSDrive
        if ($drive.Free -and $drive.Free -lt 1MB) {
            Write-Fatal "디스크 공간이 부족합니다. (사용 가능: $([math]::Round($drive.Free / 1KB))KB)"
        }
    }
    catch {
        # 디스크 공간 확인 실패 시 무시 (WSL 등)
    }
}

# --- 디렉토리 생성 (멱등) ---------------------------------------------------

function Ensure-Directory {
    param([string]$DirPath)

    if (Test-Path $DirPath -PathType Container) {
        return
    }

    $rel = $DirPath.Replace($script:TargetDir, "").TrimStart('\', '/')

    if ($DryRun) {
        Write-Dry "디렉토리 생성 예정: $rel\"
    }
    else {
        New-Item -ItemType Directory -Path $DirPath -Force | Out-Null
        Write-Ok "디렉토리 생성: $rel\"
    }
    $script:CountDirCreated++
}

# --- 파일 복사 핵심 로직 ----------------------------------------------------

function Copy-ConfigFile {
    param(
        [string]$SrcRel,
        [string]$DstRel
    )

    $src = Join-Path $script:ScriptDir $SrcRel
    $dst = Join-Path $script:TargetDir $DstRel

    # 대상 디렉토리 확보
    $dstDir = Split-Path -Parent $dst
    Ensure-Directory $dstDir

    # --- dry-run ---
    if ($DryRun) {
        if (Test-Path $dst) {
            if ((Test-Protected $dst) -and (Get-Item $dst).Length -gt 0) {
                Write-Dry "건너뜀 (보호 파일): $DstRel"
                $script:CountProtected++
            }
            elseif (Test-FilesIdentical $src $dst) {
                Write-Dry "변경 없음 (동일): $DstRel"
                $script:CountSkipped++
            }
            else {
                Write-Dry "덮어쓰기 예정: $DstRel"
                $script:CountCopied++
            }
        }
        else {
            Write-Dry "새로 생성 예정: $DstRel"
            $script:CountCopied++
        }
        return
    }

    # --- 파일 미존재: 새로 복사 ---
    if (-not (Test-Path $dst)) {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Ok "설치 완료: $DstRel"
        $script:CountCopied++
        return
    }

    # --- 내용 동일: 건너뜀 (멱등성) ---
    if (Test-FilesIdentical $src $dst) {
        Write-Skip "이미 동일: $DstRel"
        $script:CountSkipped++
        return
    }

    # --- 보호 파일: 사용자 데이터 보존 ---
    if (Test-Protected $dst) {
        Write-Warn "건너뜀 (보호 파일 -- 사용자 데이터 보존): $DstRel"
        $script:CountProtected++
        return
    }

    # --- -Force: 백업 없이 덮어쓰기 ---
    if ($Force) {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Ok "덮어쓰기 완료 (-Force): $DstRel"
        $script:CountCopied++
        return
    }

    # --- 기본: 백업 후 덮어쓰기 (중복 백업 방지) ---
    $backup = "$dst.backup"
    if ((Test-Path $backup) -and (Test-FilesIdentical $dst $backup)) {
        # 기존 백업이 현재 파일과 동일 -> 백업 갱신 불필요
    }
    else {
        Copy-Item -Path $dst -Destination $backup -Force
        Write-Info "백업 생성: ${DstRel}.backup"
        $script:CountBackedUp++
    }
    Copy-Item -Path $src -Destination $dst -Force
    Write-Ok "업데이트 완료: $DstRel"
    $script:CountCopied++
}

# --- Kiro 설치 --------------------------------------------------------------

function Install-Kiro {
    Write-Host ""
    Write-Host "  -- Kiro 설정 파일 --" -ForegroundColor White
    Write-Host ""

    # Steering
    Copy-ConfigFile "kiro\steering\boundaries.md"  ".kiro\steering\boundaries.md"
    Copy-ConfigFile "kiro\steering\conventions.md"  ".kiro\steering\conventions.md"
    Copy-ConfigFile "kiro\steering\learnings.md"    ".kiro\steering\learnings.md"
    Copy-ConfigFile "kiro\steering\self-review.md"      ".kiro\steering\self-review.md"
    Copy-ConfigFile "kiro\steering\fswrite-rule.md"     ".kiro\steering\fswrite-rule.md"
    Copy-ConfigFile "kiro\steering\builders-use-uv.md"  ".kiro\steering\builders-use-uv.md"

    # Hooks
    Copy-ConfigFile "kiro\hooks\post-task-review.kiro.hook"  ".kiro\hooks\post-task-review.kiro.hook"
    Copy-ConfigFile "kiro\hooks\periodic-review.kiro.hook"    ".kiro\hooks\periodic-review.kiro.hook"
}

# --- .gitignore 힌트 --------------------------------------------------------

function Show-GitignoreHint {
    $gitignore = Join-Path $script:TargetDir ".gitignore"
    if (-not (Test-Path $gitignore)) { return }

    $content = Get-Content $gitignore -Raw -ErrorAction SilentlyContinue
    if ($content -notmatch '\.kiro/steering/learnings\.md') {
        Write-Host ""
        Write-Host "  [참고] " -ForegroundColor Yellow -NoNewline
        Write-Host "learnings.md는 개인 학습 기록입니다."
        Write-Host "        팀 프로젝트라면 .gitignore에 추가를 고려하세요:"
        Write-Host "        echo '.kiro/steering/learnings.md' >> .gitignore"
    }
}

# --- 결과 요약 --------------------------------------------------------------

function Show-Summary {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    if ($DryRun) {
        Write-Host " 미리보기 결과 요약" -ForegroundColor Cyan
    }
    else {
        Write-Host " 설치 완료" -ForegroundColor Green
    }
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  대상 프로젝트 : " -NoNewline
    Write-Host $script:TargetDir -ForegroundColor Cyan
    Write-Host ""

    if ($script:CountDirCreated -gt 0) { Write-Host "  - 디렉토리 생성 $($script:CountDirCreated)개" }
    if ($script:CountCopied -gt 0)     { Write-Host "  - 파일 복사 $($script:CountCopied)개" }
    if ($script:CountBackedUp -gt 0)   { Write-Host "  - 백업 생성 $($script:CountBackedUp)개" }
    if ($script:CountSkipped -gt 0)    { Write-Host "  - 건너뜀 (동일) $($script:CountSkipped)개" }
    if ($script:CountProtected -gt 0)  { Write-Host "  - 건너뜀 (보호) $($script:CountProtected)개" }

    # 다음 단계
    if (-not $DryRun -and $script:CountCopied -gt 0) {
        Write-Host ""
        Write-Host "  다음 단계:" -ForegroundColor White
        Write-Host "    - .kiro\steering\conventions.md 에서 기술 스택을 프로젝트에 맞게 수정"
        Write-Host "    - .kiro\steering\boundaries.md 에서 프로젝트별 규칙 추가"
    }

    if ($DryRun) {
        Write-Host ""
        Write-Info "미리보기 모드입니다. 실제 파일은 변경되지 않았습니다."
        Write-Info "-DryRun 을 제거하고 다시 실행하면 설치됩니다."
    }

    # .gitignore 힌트
    Show-GitignoreHint

    # 참고 문서
    Write-Host ""
    Write-Host "  자세한 사용법:"
    Write-Host "    - Kiro: " -NoNewline
    Write-Host "$($script:ScriptDir)\kiro\README.md" -ForegroundColor Cyan
    Write-Host ""
}

# --- 메인 -------------------------------------------------------------------

function Main {
    # 도움말 / 버전
    if ($Help) { Show-Help; return }
    if ($ShowVersion) { Write-Host "install.ps1 v$($script:AppVersion)"; return }

    # 헤더
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host " Agentic Coding Guide 설치 v$($script:AppVersion)" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""

    # 모드 표시
    if ($DryRun) {
        Write-Info "미리보기 모드 (-DryRun): 실제 파일 변경 없음"
    }
    if ($Force) {
        Write-Warn "강제 모드 (-Force): 기존 파일을 백업 없이 덮어씁니다"
    }

    # 대상 디렉토리 결정
    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        $ProjectPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "builders-program-0416"
    }
    if (-not (Test-Path $ProjectPath)) {
        Write-Info "프로젝트 디렉토리를 생성합니다: $ProjectPath"
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    }
    Resolve-TargetDir $ProjectPath

    Write-Info "소스 디렉토리: $($script:ScriptDir)"
    Write-Info "대상 프로젝트: $($script:TargetDir)"

    # 자기 자신에게 설치 방지
    Test-SelfInstall

    # 프로젝트 디렉토리 확인
    Test-ProjectIndicators

    # 디스크 공간 확인
    Test-DiskSpace

    # 소스 파일 검증
    Test-SourceFiles

    # 설치 실행
    Install-Kiro

    # 결과 요약
    Show-Summary
}

# Ctrl+C 핸들러
try {
    Main
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-Host ""
    Write-Warn "설치가 중단되었습니다."
    Write-Warn "이미 복사된 파일은 유지됩니다. 다시 실행하면 안전하게 이어갑니다."
    exit 130
}
