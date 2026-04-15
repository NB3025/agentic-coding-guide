#!/usr/bin/env bash
# =============================================================================
# install.sh - Agentic Coding Guide 설치 스크립트
#
# 사용법:
#   ./install.sh [옵션] [프로젝트_경로]
#
# 옵션:
#   --kiro          Kiro 설정 파일만 설치
#   --claude-code   Claude Code 설정 파일만 설치
#   --all           모든 설정 파일 설치
#   --dry-run       실제 복사 없이 미리보기
#   --force         기존 파일 백업 없이 덮어쓰기
#   --help, -h      도움말 표시
#   --version, -v   버전 표시
#
# 프로젝트 경로를 생략하면 현재 디렉토리를 대상으로 함
# 플래그를 생략하면 대화형 메뉴 표시
# =============================================================================

set -euo pipefail

readonly VERSION="2.1.0"

# ─── 스크립트 소스 디렉토리 결정 (심볼릭 링크 해결) ─────────────────────────
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -L "$source" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

readonly SCRIPT_DIR="$(resolve_script_dir)"

# learnings.md 는 사용자 데이터가 축적되므로 덮어쓰지 않는다
readonly PROTECTED_FILES=("learnings.md")

# ─── 색상 ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
    CYAN="$(tput setaf 6)"; BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
else
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" DIM="" RESET=""
fi

info()  { echo "  ${CYAN}[정보]${RESET} $*"; }
ok()    { echo "  ${GREEN}[완료]${RESET} $*"; }
skip_() { echo "  ${DIM}[건너뜀]${RESET} $*"; }
warn()  { echo "  ${YELLOW}[경고]${RESET} $*"; }
err()   { echo "  ${RED}[오류]${RESET} $*" >&2; }
dry()   { echo "  ${CYAN}[미리보기]${RESET} $*"; }
die()   { err "$@"; exit 1; }

# ─── 전역 상태 ──────────────────────────────────────────────────────────────
TARGET_DIR=""
INSTALL_KIRO=false
INSTALL_CLAUDE=false
DRY_RUN=false
FORCE=false

# 결과 카운터
COUNT_COPIED=0
COUNT_BACKED_UP=0
COUNT_SKIPPED=0
COUNT_PROTECTED=0
COUNT_DIR_CREATED=0

# ─── Ctrl+C 핸들러 ──────────────────────────────────────────────────────────
cleanup() {
    echo ""
    warn "설치가 중단되었습니다."
    warn "이미 복사된 파일은 유지됩니다. 다시 실행하면 안전하게 이어갑니다."
    exit 130
}
trap cleanup INT TERM

# ─── 플랫폼 감지 ────────────────────────────────────────────────────────────
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)                echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*)  echo "windows-bash" ;;
        *)                      echo "unknown" ;;
    esac
}

# ─── 보호 파일 확인 ─────────────────────────────────────────────────────────
is_protected() {
    local filename
    filename="$(basename "$1")"
    for pf in "${PROTECTED_FILES[@]}"; do
        [[ "$filename" == "$pf" ]] && return 0
    done
    return 1
}

# ─── 소스 파일 검증 ─────────────────────────────────────────────────────────
validate_source() {
    local missing=()

    if $INSTALL_KIRO; then
        local kiro_files=(
            "kiro/steering/boundaries.md"
            "kiro/steering/conventions.md"
            "kiro/steering/learnings.md"
            "kiro/steering/self-review.md"
            "kiro/hooks/post-task-review.kiro.hook"
            "kiro/hooks/periodic-review.kiro.hook"
        )
        for f in "${kiro_files[@]}"; do
            [[ -f "$SCRIPT_DIR/$f" ]] || missing+=("$f")
        done
    fi

    if $INSTALL_CLAUDE; then
        local claude_files=(
            "claude-code/CLAUDE.md"
            "claude-code/learnings.md"
        )
        for f in "${claude_files[@]}"; do
            [[ -f "$SCRIPT_DIR/$f" ]] || missing+=("$f")
        done
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        err "소스 파일이 누락되었습니다:"
        for f in "${missing[@]}"; do
            err "  - $f"
        done
        die "저장소가 올바르게 클론되었는지 확인하세요."
    fi
}

# ─── 대상 디렉토리 검증 ─────────────────────────────────────────────────────
validate_target() {
    local candidate="$1"

    # 절대 경로로 변환
    if [[ "$candidate" != /* ]]; then
        candidate="$(cd "$candidate" 2>/dev/null && pwd)" \
            || die "경로를 찾을 수 없습니다: $1"
    fi

    [[ -d "$candidate" ]] || die "디렉토리가 존재하지 않습니다: $candidate"
    [[ -w "$candidate" ]] || die "쓰기 권한이 없습니다: $candidate"

    TARGET_DIR="$candidate"
}

# ─── 자기 자신에게 설치 방지 ─────────────────────────────────────────────────
check_self_install() {
    local real_script real_target
    real_script="$(cd -P "$SCRIPT_DIR" && pwd)"
    real_target="$(cd -P "$TARGET_DIR" && pwd)"

    if [[ "$real_script" == "$real_target" ]]; then
        err "이 저장소 자체에는 설치할 수 없습니다."
        err "대상 프로젝트 경로를 인자로 전달하세요."
        echo ""
        echo "    예: $0 --all /path/to/my-project"
        exit 1
    fi
}

# ─── 프로젝트 디렉토리 휴리스틱 확인 ────────────────────────────────────────
check_project_indicators() {
    local indicators=0
    for marker in .git package.json pyproject.toml Cargo.toml go.mod \
                  pom.xml build.gradle Makefile .gitignore; do
        [[ -e "$TARGET_DIR/$marker" ]] && indicators=$((indicators + 1))
    done

    if [[ $indicators -eq 0 ]]; then
        warn "프로젝트 파일이 감지되지 않았습니다: $TARGET_DIR"
        warn "프로젝트 루트 디렉토리가 맞는지 확인하세요."
        if ! $DRY_RUN && ! $FORCE; then
            echo ""
            echo -n "  계속 진행하시겠습니까? [y/N] "
            read -r confirm
            [[ "$confirm" =~ ^[yY]$ ]] || { info "설치를 취소합니다."; exit 0; }
        fi
    fi
}

# ─── 디스크 공간 확인 ───────────────────────────────────────────────────────
check_disk_space() {
    if command -v df &>/dev/null; then
        local avail_kb
        avail_kb=$(df -k "$TARGET_DIR" 2>/dev/null | awk 'NR==2 {print $4}')
        if [[ -n "$avail_kb" ]] && [[ "$avail_kb" -lt 1024 ]]; then
            die "디스크 공간이 부족합니다. (사용 가능: ${avail_kb}KB)"
        fi
    fi
}

# ─── 디렉토리 생성 (멱등) ───────────────────────────────────────────────────
ensure_dir() {
    local dir="$1"
    local rel="${dir#"$TARGET_DIR"/}"

    [[ -d "$dir" ]] && return 0

    if $DRY_RUN; then
        dry "디렉토리 생성 예정: $rel/"
    else
        mkdir -p "$dir"
        ok "디렉토리 생성: $rel/"
    fi
    COUNT_DIR_CREATED=$((COUNT_DIR_CREATED + 1))
}

# ─── 파일 복사 핵심 로직 ────────────────────────────────────────────────────
#
# 처리 순서:
#   1. 대상 디렉토리 확보
#   2. 파일 미존재 -> 새로 복사
#   3. 내용 동일 -> 건너뜀 (멱등성)
#   4. 보호 파일 (learnings.md) -> 건너뜀
#   5. --force -> 백업 없이 덮어쓰기
#   6. 기본 -> .backup 으로 백업 후 덮어쓰기 (중복 백업 방지)
#   7. --dry-run 모드에서는 실제 변경 없이 계획만 출력
#
copy_file() {
    local src_rel="$1"
    local dst_rel="$2"
    local src="${SCRIPT_DIR}/${src_rel}"
    local dst="${TARGET_DIR}/${dst_rel}"

    # 대상 디렉토리 확보
    ensure_dir "$(dirname "$dst")"

    # --- dry-run ---
    if $DRY_RUN; then
        if [[ -f "$dst" ]]; then
            if is_protected "$dst" && [[ -s "$dst" ]]; then
                dry "건너뜀 (보호 파일): $dst_rel"
                COUNT_PROTECTED=$((COUNT_PROTECTED + 1))
            elif diff -q "$src" "$dst" >/dev/null 2>&1; then
                dry "변경 없음 (동일): $dst_rel"
                COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
            else
                dry "덮어쓰기 예정: $dst_rel"
                COUNT_COPIED=$((COUNT_COPIED + 1))
            fi
        else
            dry "새로 생성 예정: $dst_rel"
            COUNT_COPIED=$((COUNT_COPIED + 1))
        fi
        return 0
    fi

    # --- 파일 미존재: 새로 복사 ---
    if [[ ! -f "$dst" ]]; then
        cp "$src" "$dst"
        ok "설치 완료: $dst_rel"
        COUNT_COPIED=$((COUNT_COPIED + 1))
        return 0
    fi

    # --- 내용 동일: 건너뜀 (멱등성) ---
    if diff -q "$src" "$dst" >/dev/null 2>&1; then
        skip_ "이미 동일: $dst_rel"
        COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
        return 0
    fi

    # --- 보호 파일: 사용자 데이터 보존 ---
    if is_protected "$dst"; then
        warn "건너뜀 (보호 파일 -- 사용자 데이터 보존): $dst_rel"
        COUNT_PROTECTED=$((COUNT_PROTECTED + 1))
        return 0
    fi

    # --- --force: 백업 없이 덮어쓰기 ---
    if $FORCE; then
        cp "$src" "$dst"
        ok "덮어쓰기 완료 (--force): $dst_rel"
        COUNT_COPIED=$((COUNT_COPIED + 1))
        return 0
    fi

    # --- 기본: 백업 후 덮어쓰기 (중복 백업 방지) ---
    local backup="${dst}.backup"
    if [[ -f "$backup" ]] && diff -q "$dst" "$backup" >/dev/null 2>&1; then
        : # 기존 백업이 현재 파일과 동일하면 백업 갱신 불필요
    else
        cp "$dst" "$backup"
        info "백업 생성: ${dst_rel}.backup"
        COUNT_BACKED_UP=$((COUNT_BACKED_UP + 1))
    fi
    cp "$src" "$dst"
    ok "업데이트 완료: $dst_rel"
    COUNT_COPIED=$((COUNT_COPIED + 1))
}

# ─── Kiro 설치 ──────────────────────────────────────────────────────────────
install_kiro() {
    echo ""
    echo "  ${BOLD}-- Kiro 설정 파일 --${RESET}"
    echo ""

    # Steering
    copy_file "kiro/steering/boundaries.md"  ".kiro/steering/boundaries.md"
    copy_file "kiro/steering/conventions.md"  ".kiro/steering/conventions.md"
    copy_file "kiro/steering/learnings.md"    ".kiro/steering/learnings.md"
    copy_file "kiro/steering/self-review.md"  ".kiro/steering/self-review.md"

    # Hooks
    copy_file "kiro/hooks/post-task-review.kiro.hook"  ".kiro/hooks/post-task-review.kiro.hook"
    copy_file "kiro/hooks/periodic-review.kiro.hook"    ".kiro/hooks/periodic-review.kiro.hook"
}

# ─── Claude Code 설치 ───────────────────────────────────────────────────────
install_claude_code() {
    echo ""
    echo "  ${BOLD}-- Claude Code 설정 파일 --${RESET}"
    echo ""

    copy_file "claude-code/CLAUDE.md"       "CLAUDE.md"
    copy_file "claude-code/learnings.md"    ".claude/learnings.md"
}

# ─── 대화형 메뉴 ────────────────────────────────────────────────────────────
select_interactive() {
    echo ""
    echo "  ${BOLD}설치할 항목을 선택하세요:${RESET}"
    echo ""
    echo "    ${BOLD}1)${RESET} Kiro          -- .kiro/steering, .kiro/hooks"
    echo "    ${BOLD}2)${RESET} Claude Code   -- CLAUDE.md, .claude/learnings.md"
    echo "    ${BOLD}3)${RESET} 모두 설치     -- Kiro + Claude Code"
    echo "    ${BOLD}q)${RESET} 취소"
    echo ""
    echo -n "  선택 (1/2/3/q): "
    read -r choice

    case "$choice" in
        1) INSTALL_KIRO=true ;;
        2) INSTALL_CLAUDE=true ;;
        3) INSTALL_KIRO=true; INSTALL_CLAUDE=true ;;
        q|Q) info "설치를 취소합니다."; exit 0 ;;
        *) die "잘못된 선택입니다: $choice" ;;
    esac
}

# ─── .gitignore 힌트 ────────────────────────────────────────────────────────
suggest_gitignore() {
    local gitignore="$TARGET_DIR/.gitignore"
    [[ -f "$gitignore" ]] || return 0

    local suggestions=()

    if $INSTALL_KIRO; then
        grep -q '\.kiro/steering/learnings\.md' "$gitignore" 2>/dev/null \
            || suggestions+=(".kiro/steering/learnings.md")
    fi

    if $INSTALL_CLAUDE; then
        grep -q '\.claude/learnings\.md' "$gitignore" 2>/dev/null \
            || suggestions+=(".claude/learnings.md")
    fi

    if [[ ${#suggestions[@]} -gt 0 ]]; then
        echo ""
        echo "  ${YELLOW}[참고]${RESET} learnings.md는 개인 학습 기록입니다."
        echo "        팀 프로젝트라면 .gitignore에 추가를 고려하세요:"
        for s in "${suggestions[@]}"; do
            echo "        echo '$s' >> .gitignore"
        done
    fi
}

# ─── 결과 요약 ──────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo "${BOLD}========================================${RESET}"
    if $DRY_RUN; then
        echo "${CYAN}${BOLD} 미리보기 결과 요약${RESET}"
    else
        echo "${GREEN}${BOLD} 설치 완료${RESET}"
    fi
    echo "${BOLD}========================================${RESET}"
    echo ""
    echo "  대상 프로젝트 : ${CYAN}${TARGET_DIR}${RESET}"
    echo ""

    local items=()
    [[ $COUNT_DIR_CREATED -gt 0 ]] && items+=("디렉토리 생성 ${COUNT_DIR_CREATED}개")
    [[ $COUNT_COPIED -gt 0 ]]      && items+=("파일 복사 ${COUNT_COPIED}개")
    [[ $COUNT_BACKED_UP -gt 0 ]]   && items+=("백업 생성 ${COUNT_BACKED_UP}개")
    [[ $COUNT_SKIPPED -gt 0 ]]     && items+=("건너뜀 (동일) ${COUNT_SKIPPED}개")
    [[ $COUNT_PROTECTED -gt 0 ]]   && items+=("건너뜀 (보호) ${COUNT_PROTECTED}개")

    for item in "${items[@]}"; do
        echo "  - $item"
    done

    # 다음 단계 안내
    if ! $DRY_RUN && [[ $COUNT_COPIED -gt 0 ]]; then
        echo ""
        echo "  ${BOLD}다음 단계:${RESET}"
        if $INSTALL_KIRO; then
            echo "    - .kiro/steering/conventions.md 에서 기술 스택을 프로젝트에 맞게 수정"
            echo "    - .kiro/steering/boundaries.md 에서 프로젝트별 규칙 추가"
        fi
        if $INSTALL_CLAUDE; then
            echo "    - CLAUDE.md 에서 Stack 섹션을 프로젝트에 맞게 수정"
            echo "    - .claude/learnings.md 는 에이전트가 자동으로 학습을 축적합니다"
        fi
    fi

    if $DRY_RUN; then
        echo ""
        info "미리보기 모드입니다. 실제 파일은 변경되지 않았습니다."
        info "--dry-run 을 제거하고 다시 실행하면 설치됩니다."
    fi

    # .gitignore 힌트
    suggest_gitignore

    # 참고 문서
    echo ""
    echo "  자세한 사용법:"
    if $INSTALL_KIRO; then
        echo "    - Kiro:        ${CYAN}${SCRIPT_DIR}/kiro/README.md${RESET}"
    fi
    if $INSTALL_CLAUDE; then
        echo "    - Claude Code: ${CYAN}${SCRIPT_DIR}/claude-code/README.md${RESET}"
    fi
    echo ""
}

# ─── 도움말 (English) ──────────────────────────────────────────────────────
show_help() {
    cat <<'EOF'
Usage: install.sh [OPTIONS] [PROJECT_PATH]

Install agentic-coding-guide config files into your project.

OPTIONS:
  --kiro          Install Kiro config only (.kiro/steering, .kiro/hooks)
  --claude-code   Install Claude Code config only (CLAUDE.md, .claude/learnings.md)
  --all           Install both Kiro + Claude Code
  --dry-run       Preview what would be done without making changes
  --force         Overwrite existing files without backup
  --backup, -b    Backup existing files before overwriting (default behavior)
  --help, -h      Show this help message
  --version, -v   Show version

ARGUMENTS:
  PROJECT_PATH    Target project directory (default: current directory)

CONFLICT HANDLING:
  - Default: backs up existing files as .backup, then replaces with new version
  - --force: overwrites without backup
  - Identical content: auto-skipped (idempotent)
  - learnings.md: NEVER overwritten (protected; accumulates user data)

EXAMPLES:
  # Interactive install into current directory (shows menu)
  cd /my/project && /path/to/install.sh

  # Install everything into a specific project
  ./install.sh --all /path/to/my-project

  # Preview only (no file changes)
  ./install.sh --all --dry-run /path/to/my-project

  # Overwrite without backup
  ./install.sh --kiro --force /path/to/my-project

FILES INSTALLED:
  --kiro:
    .kiro/steering/boundaries.md
    .kiro/steering/conventions.md
    .kiro/steering/self-review.md
    .kiro/steering/learnings.md     (protected: never overwrites existing)
    .kiro/hooks/post-task-review.kiro.hook
    .kiro/hooks/periodic-review.kiro.hook

  --claude-code:
    CLAUDE.md
    .claude/learnings.md            (protected: never overwrites existing)
EOF
}

# ─── 인자 파싱 ──────────────────────────────────────────────────────────────
parse_args() {
    local positional_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --kiro)         INSTALL_KIRO=true;  shift ;;
            --claude-code)  INSTALL_CLAUDE=true; shift ;;
            --all)          INSTALL_KIRO=true; INSTALL_CLAUDE=true; shift ;;
            --dry-run)      DRY_RUN=true;  shift ;;
            --force)        FORCE=true;    shift ;;
            --backup|-b)    shift ;;  # backup is the default behavior; flag accepted for clarity
            --help|-h)      show_help; exit 0 ;;
            --version|-v)   echo "install.sh v${VERSION}"; exit 0 ;;
            -*)             die "알 수 없는 옵션: $1  ('$0 --help' 참고)" ;;
            *)              positional_args+=("$1"); shift ;;
        esac
    done

    if [[ ${#positional_args[@]} -gt 1 ]]; then
        die "프로젝트 경로는 하나만 지정할 수 있습니다."
    fi

    TARGET_DIR="${positional_args[0]:-$(pwd)}"
}

# ─── 메인 ───────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    # 헤더
    echo ""
    echo "${BOLD}========================================${RESET}"
    echo "${BOLD} Agentic Coding Guide 설치 v${VERSION}${RESET}"
    echo "${BOLD}========================================${RESET}"
    echo ""

    # 모드 표시
    if $DRY_RUN; then
        info "미리보기 모드 (--dry-run): 실제 파일 변경 없음"
    fi
    if $FORCE; then
        warn "강제 모드 (--force): 기존 파일을 백업 없이 덮어씁니다"
    fi

    # 플랫폼 감지
    local platform
    platform="$(detect_platform)"
    if [[ "$platform" == "windows-bash" ]]; then
        warn "Windows bash 환경입니다. PowerShell 사용자는 install.ps1을 실행하세요."
    fi

    # 대상 디렉토리 검증
    validate_target "$TARGET_DIR"

    info "소스 디렉토리: $SCRIPT_DIR"
    info "대상 프로젝트: $TARGET_DIR"

    # 자기 자신에게 설치 방지
    check_self_install

    # 프로젝트 디렉토리 확인
    check_project_indicators

    # 디스크 공간 확인
    check_disk_space

    # 플래그가 없으면 대화형 메뉴
    if ! $INSTALL_KIRO && ! $INSTALL_CLAUDE; then
        select_interactive
    fi

    # 소스 파일 검증
    validate_source

    # 설치 실행
    if $INSTALL_KIRO; then
        install_kiro
    fi
    if $INSTALL_CLAUDE; then
        install_claude_code
    fi

    # 결과 요약
    print_summary
}

main "$@"
