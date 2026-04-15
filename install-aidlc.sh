#!/usr/bin/env bash
# =============================================================================
# install-aidlc.sh - AWS AIDLC Rules 설치 스크립트
#
# 사용법:
#   ./install-aidlc.sh [프로젝트_경로]
#
# 프로젝트 경로를 생략하면 현재 디렉토리를 대상으로 함
# =============================================================================

set -euo pipefail

readonly AIDLC_REPO="https://github.com/awslabs/aidlc-workflows.git"
readonly AIDLC_DIR_NAME="aidlc-workflows"

# --- 색상 -------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
    CYAN="$(tput setaf 6)"; RED="$(tput setaf 1)"
    BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
    GREEN="" YELLOW="" CYAN="" RED="" BOLD="" RESET=""
fi

info()  { echo "  ${CYAN}[정보]${RESET} $*"; }
ok()    { echo "  ${GREEN}[완료]${RESET} $*"; }
warn()  { echo "  ${YELLOW}[경고]${RESET} $*"; }
err()   { echo "  ${RED}[오류]${RESET} $*" >&2; }
die()   { err "$@"; exit 1; }

# --- 메인 -------------------------------------------------------------------
main() {
    local project_dir="${1:-$(pwd)}"

    # 절대 경로로 변환
    if [[ "$project_dir" != /* ]]; then
        project_dir="$(cd "$project_dir" 2>/dev/null && pwd)" \
            || die "경로를 찾을 수 없습니다: $1"
    fi

    [[ -d "$project_dir" ]] || die "디렉토리가 존재하지 않습니다: $project_dir"

    local parent_dir
    parent_dir="$(dirname "$project_dir")"
    local clone_dir="${parent_dir}/${AIDLC_DIR_NAME}"

    # 헤더
    echo ""
    echo "${BOLD}========================================${RESET}"
    echo "${BOLD} AWS AIDLC Rules 설치${RESET}"
    echo "${BOLD}========================================${RESET}"
    echo ""
    info "프로젝트: $project_dir"
    info "클론 위치: $clone_dir"

    # 1. git clone (이미 있으면 pull)
    echo ""
    if [[ -d "$clone_dir/.git" ]]; then
        info "이미 클론되어 있습니다. 최신으로 업데이트합니다..."
        git -C "$clone_dir" pull --ff-only || warn "업데이트 실패. 기존 버전을 사용합니다."
    else
        info "aidlc-workflows 클론 중..."
        git clone "$AIDLC_REPO" "$clone_dir" || die "git clone 실패"
    fi
    ok "aidlc-workflows 준비 완료"

    # 소스 경로 확인
    local rules_src="${clone_dir}/aidlc-rules/aws-aidlc-rules"
    local details_src="${clone_dir}/aidlc-rules/aws-aidlc-rule-details"

    [[ -d "$rules_src" ]] || die "소스 경로를 찾을 수 없습니다: $rules_src"
    [[ -d "$details_src" ]] || die "소스 경로를 찾을 수 없습니다: $details_src"

    # 2. 디렉토리 생성
    echo ""
    mkdir -p "${project_dir}/.kiro/steering"
    ok ".kiro/steering 디렉토리 준비"

    # 3. aws-aidlc-rules -> .kiro/steering/
    cp -R "$rules_src" "${project_dir}/.kiro/steering/"
    ok "aws-aidlc-rules -> .kiro/steering/aws-aidlc-rules"

    # 4. aws-aidlc-rule-details -> .kiro/
    cp -R "$details_src" "${project_dir}/.kiro/"
    ok "aws-aidlc-rule-details -> .kiro/aws-aidlc-rule-details"

    # 완료
    echo ""
    echo "${BOLD}========================================${RESET}"
    echo "${GREEN}${BOLD} 설치 완료${RESET}"
    echo "${BOLD}========================================${RESET}"
    echo ""
    echo "  설치된 파일:"
    echo "    ${CYAN}.kiro/steering/aws-aidlc-rules/${RESET}"
    echo "    ${CYAN}.kiro/aws-aidlc-rule-details/${RESET}"
    echo ""
}

main "$@"
