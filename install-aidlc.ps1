﻿# =============================================================================
# install-aidlc.ps1 - AWS AIDLC Rules 설치 스크립트 (PowerShell)
#
# 사용법:
#   .\install-aidlc.ps1 <프로젝트_경로>
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:AidlcRepo = "https://github.com/awslabs/aidlc-workflows.git"
$script:AidlcDirName = "aidlc-workflows"

# --- 색상 출력 헬퍼 ---------------------------------------------------------

function Write-Info  { param([string]$Msg) Write-Host "  [정보] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "  [완료] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "  [경고] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "  [오류] $Msg" -ForegroundColor Red }

function Write-Fatal {
    param([string]$Msg)
    Write-Err $Msg
    exit 1
}

# --- 메인 -------------------------------------------------------------------

function Main {
    # 프로젝트 경로 필수
    if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
        Write-Err "프로젝트 경로를 지정해야 합니다."
        Write-Host ""
        Write-Host "  사용법: .\install-aidlc.ps1 <프로젝트_경로>"
        Write-Host "  예:     .\install-aidlc.ps1 C:\path\to\my-project"
        exit 1
    }

    $resolved = Resolve-Path -Path $ProjectPath -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Fatal "경로를 찾을 수 없습니다: $ProjectPath"
    }
    $projectDir = $resolved.Path

    if (-not (Test-Path $projectDir -PathType Container)) {
        Write-Fatal "디렉토리가 존재하지 않습니다: $projectDir"
    }

    $parentDir = Split-Path -Parent $projectDir
    $cloneDir = Join-Path $parentDir $script:AidlcDirName

    # 헤더
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host " AWS AIDLC Rules 설치" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
    Write-Info "프로젝트: $projectDir"
    Write-Info "클론 위치: $cloneDir"

    # 1. git clone (이미 있으면 pull)
    Write-Host ""
    if (Test-Path (Join-Path $cloneDir ".git")) {
        Write-Info "이미 클론되어 있습니다. 최신으로 업데이트합니다..."
        try {
            git -C $cloneDir pull --ff-only
        }
        catch {
            Write-Warn "업데이트 실패. 기존 버전을 사용합니다."
        }
    }
    else {
        Write-Info "aidlc-workflows 클론 중..."
        git clone $script:AidlcRepo $cloneDir
        if ($LASTEXITCODE -ne 0) {
            Write-Fatal "git clone 실패"
        }
    }
    Write-Ok "aidlc-workflows 준비 완료"

    # 소스 경로 확인
    $rulesSrc = Join-Path $cloneDir "aidlc-rules\aws-aidlc-rules"
    $detailsSrc = Join-Path $cloneDir "aidlc-rules\aws-aidlc-rule-details"

    if (-not (Test-Path $rulesSrc)) {
        Write-Fatal "소스 경로를 찾을 수 없습니다: $rulesSrc"
    }
    if (-not (Test-Path $detailsSrc)) {
        Write-Fatal "소스 경로를 찾을 수 없습니다: $detailsSrc"
    }

    # 2. 디렉토리 생성
    Write-Host ""
    $steeringDir = Join-Path $projectDir ".kiro\steering"
    if (-not (Test-Path $steeringDir)) {
        New-Item -ItemType Directory -Path $steeringDir -Force | Out-Null
    }
    Write-Ok ".kiro\steering 디렉토리 준비"

    # 3. aws-aidlc-rules -> .kiro\steering\
    $rulesDst = Join-Path $steeringDir "aws-aidlc-rules"
    if (Test-Path $rulesDst) {
        Remove-Item -Recurse -Force $rulesDst
    }
    Copy-Item -Recurse -Path $rulesSrc -Destination $rulesDst
    Write-Ok "aws-aidlc-rules -> .kiro\steering\aws-aidlc-rules"

    # 4. aws-aidlc-rule-details -> .kiro\
    $kiroDir = Join-Path $projectDir ".kiro"
    $detailsDst = Join-Path $kiroDir "aws-aidlc-rule-details"
    if (Test-Path $detailsDst) {
        Remove-Item -Recurse -Force $detailsDst
    }
    Copy-Item -Recurse -Path $detailsSrc -Destination $detailsDst
    Write-Ok "aws-aidlc-rule-details -> .kiro\aws-aidlc-rule-details"

    # 완료
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host " 설치 완료" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  설치된 파일:"
    Write-Host "    .kiro\steering\aws-aidlc-rules\" -ForegroundColor Cyan
    Write-Host "    .kiro\aws-aidlc-rule-details\" -ForegroundColor Cyan
    Write-Host ""
}

try {
    Main
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-Host ""
    Write-Warn "설치가 중단되었습니다."
    exit 130
}
