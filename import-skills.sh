#!/usr/bin/env bash
#
# Agent Skills Sync (Claude Code & Antigravity)
#
# Synchronizes local custom workspace skills to Claude Code (~/.claude/skills)
# and Google Antigravity (~/.gemini/config/skills).
#

set -eo pipefail

# -----------------------------------------------------------------------------
# Color Codes
# -----------------------------------------------------------------------------
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[0;36m"
COLOR_YELLOW="\033[1;33m"
COLOR_GREEN="\033[0;32m"
COLOR_MAGENTA="\033[0;35m"
COLOR_RED="\033[0;31m"
COLOR_DARK_GRAY="\033[1;30m"
COLOR_WHITE="\033[1;37m"

# -----------------------------------------------------------------------------
# Default Options
# -----------------------------------------------------------------------------
TARGET="all"
FORCE=false

# -----------------------------------------------------------------------------
# Usage & Help
# -----------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Synchronizes local custom workspace skills to Claude Code and Antigravity.

Options:
  --target <all|claude|antigravity>   Target agent environment (default: all)
  --claude-only                       Sync only to Claude Code (~/.claude/skills)
  --antigravity-only                  Sync only to Antigravity (~/.gemini/config/skills)
  -f, --force                         Force re-copying of all skills even if unchanged
  -h, --help                          Show this help message and exit

Examples:
  ./$(basename "$0")                  # Sync to both Claude Code & Antigravity
  ./$(basename "$0") --claude-only    # Sync only to Claude Code
  ./$(basename "$0") --antigravity-only
  ./$(basename "$0") --force
EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Parse Arguments
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            if [[ -z "${2:-}" ]]; then
                echo -e "${COLOR_RED}Error: --target requires a value (all, claude, antigravity)${COLOR_RESET}" >&2
                exit 1
            fi
            TARGET="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --claude-only)
            TARGET="claude"
            shift
            ;;
        --antigravity-only)
            TARGET="antigravity"
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${COLOR_RED}Unknown option: $1${COLOR_RESET}" >&2
            usage
            ;;
    esac
done

if [[ "$TARGET" != "all" && "$TARGET" != "claude" && "$TARGET" != "antigravity" ]]; then
    echo -e "${COLOR_RED}Invalid target '$TARGET'. Must be one of: all, claude, antigravity.${COLOR_RESET}" >&2
    exit 1
fi

echo -e "${COLOR_CYAN}==========================================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}     Agent Skills Sync (Claude Code & Antigravity)        ${COLOR_RESET}"
echo -e "${COLOR_CYAN}==========================================================${COLOR_RESET}"

# -----------------------------------------------------------------------------
# Destination Paths & Targets
# -----------------------------------------------------------------------------
CLAUDE_DIR="$HOME/.claude/skills"
ANTIGRAVITY_DIR="$HOME/.gemini/config/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR"

declare -a TARGET_NAMES=()
declare -a TARGET_PATHS=()

if [[ "$TARGET" == "all" || "$TARGET" == "claude" ]]; then
    TARGET_NAMES+=("Claude Code")
    TARGET_PATHS+=("$CLAUDE_DIR")
fi

if [[ "$TARGET" == "all" || "$TARGET" == "antigravity" ]]; then
    TARGET_NAMES+=("Google Antigravity")
    TARGET_PATHS+=("$ANTIGRAVITY_DIR")
fi

# -----------------------------------------------------------------------------
# SHA256 Checksum Helper (macOS & Linux compatible)
# -----------------------------------------------------------------------------
compute_file_sha256() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$file" | awk '{print $NF}'
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import hashlib, sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$file"
    else
        echo "nosum"
    fi
}

get_skill_fingerprint() {
    local skill_path="$1"
    if [[ ! -d "$skill_path" ]]; then
        echo ""
        return
    fi

    local parts=""
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local fname
            fname="$(basename "$file")"
            if [[ "$fname" == ".DS_Store" || "$fname" == "desktop.ini" || "$fname" == "Thumbs.db" ]]; then
                continue
            fi
            local rel_name="${file#"$skill_path/"}"
            local hash
            hash="$(compute_file_sha256 "$file")"
            parts="${parts}${rel_name}:${hash}|"
        fi
    done < <(find "$skill_path" -type f | sort)

    echo "$parts"
}

# -----------------------------------------------------------------------------
# Helper: Discover local custom skills in workspace
# -----------------------------------------------------------------------------
get_workspace_skills() {
    local root_dir="$1"
    local found=()

    if [[ ! -d "$root_dir" ]]; then
        return
    fi

    # Primary: check ./skills/* if present
    if [[ -d "$root_dir/skills" ]]; then
        for d in "$root_dir/skills"/*; do
            if [[ -d "$d" ]]; then
                local base
                base="$(basename "$d")"
                if [[ "$base" == .* || "$base" == "node_modules" ]]; then
                    continue
                fi
                if [[ -f "$d/SKILL.md" ]]; then
                    found+=("$base")
                fi
            fi
        done
    fi

    # Fallback: check direct subdirectories in root
    for d in "$root_dir"/*; do
        if [[ -d "$d" ]]; then
            local base
            base="$(basename "$d")"
            if [[ "$base" == .* || "$base" == "node_modules" || "$base" == "skills" ]]; then
                continue
            fi
            if [[ -f "$d/SKILL.md" ]]; then
                local already_found=false
                for item in "${found[@]}"; do
                    if [[ "$item" == "$base" ]]; then
                        already_found=true
                        break
                    fi
                done
                if [[ "$already_found" == "false" ]]; then
                    found+=("$base")
                fi
            fi
        fi
    done

    printf "%s\n" "${found[@]}"
}

# -----------------------------------------------------------------------------
# Step 1: Discover Local Workspace Skills
# -----------------------------------------------------------------------------
echo -e "\n${COLOR_YELLOW}[1/3] Discovering local skills in workspace...${COLOR_RESET}"

mapfile -t DISCOVERED_SKILLS < <(get_workspace_skills "$WORKSPACE_DIR" | sort -u | grep -v '^$' || true)

if [[ ${#DISCOVERED_SKILLS[@]} -eq 0 ]]; then
    echo -e "${COLOR_YELLOW}Warning: No skills containing a 'SKILL.md' found under '$WORKSPACE_DIR/skills'.${COLOR_RESET}" >&2
    echo -e "${COLOR_DARK_GRAY}Create a skill folder under ./skills/<skill-name>/ with a SKILL.md to sync.${COLOR_RESET}"
    exit 0
fi

skills_str="$(IFS=", "; echo "${DISCOVERED_SKILLS[*]}")"
echo -e "  ${COLOR_GREEN}[OK] Found ${#DISCOVERED_SKILLS[@]} local skill(s): ${skills_str}${COLOR_RESET}"

# -----------------------------------------------------------------------------
# Step 2: Synchronize Skills to Active Targets
# -----------------------------------------------------------------------------
echo -e "\n${COLOR_YELLOW}[2/3] Synchronizing skills to target environments...${COLOR_RESET}"

declare -a REPORT_TARGET_NAMES=()
declare -a REPORT_TARGET_PATHS=()
declare -a REPORT_ADDED_COUNTS=()
declare -a REPORT_UPDATED_COUNTS=()
declare -a REPORT_UNCHANGED_COUNTS=()
declare -a REPORT_ADDED_LISTS=()
declare -a REPORT_UPDATED_LISTS=()

total_modified=0

for i in "${!TARGET_NAMES[@]}"; do
    target_name="${TARGET_NAMES[$i]}"
    target_path="${TARGET_PATHS[$i]}"

    echo -e "\n  ${COLOR_CYAN}--> Target: ${target_name} (${target_path})${COLOR_RESET}"

    if [[ ! -d "$target_path" ]]; then
        mkdir -p "$target_path"
        echo -e "      ${COLOR_DARK_GRAY}Created target directory: ${target_path}${COLOR_RESET}"
    fi

    added=()
    updated=()
    unchanged=()

    for skill_name in "${DISCOVERED_SKILLS[@]}"; do
        src_path="$WORKSPACE_DIR/skills/$skill_name"
        if [[ ! -d "$src_path" && -d "$WORKSPACE_DIR/$skill_name" ]]; then
            src_path="$WORKSPACE_DIR/$skill_name"
        fi

        dst_path="$target_path/$skill_name"

        src_fingerprint="$(get_skill_fingerprint "$src_path")"
        dst_fingerprint="$(get_skill_fingerprint "$dst_path")"

        if [[ -z "$dst_fingerprint" ]]; then
            # Brand new skill
            mkdir -p "$dst_path"
            cp -R "$src_path"/* "$dst_path"/
            added+=("$skill_name")
            echo -e "      ${COLOR_GREEN}[+] NEW:       $skill_name${COLOR_RESET}"
        elif [[ "$src_fingerprint" != "$dst_fingerprint" || "$FORCE" == "true" ]]; then
            # Modified or forced: clean destination folder to avoid orphan files
            rm -rf "$dst_path"
            mkdir -p "$dst_path"
            cp -R "$src_path"/* "$dst_path"/
            updated+=("$skill_name")
            echo -e "      ${COLOR_YELLOW}[*] UPDATED:   $skill_name${COLOR_RESET}"
        else
            unchanged+=("$skill_name")
            echo -e "      ${COLOR_DARK_GRAY}[=] UNCHANGED: $skill_name${COLOR_RESET}"
        fi
    done

    REPORT_TARGET_NAMES+=("$target_name")
    REPORT_TARGET_PATHS+=("$target_path")
    REPORT_ADDED_COUNTS+=("${#added[@]}")
    REPORT_UPDATED_COUNTS+=("${#updated[@]}")
    REPORT_UNCHANGED_COUNTS+=("${#unchanged[@]}")
    REPORT_ADDED_LISTS+=("$(IFS=", "; echo "${added[*]}")")
    REPORT_UPDATED_LISTS+=("$(IFS=", "; echo "${updated[*]}")")

    total_modified=$((total_modified + ${#added[@]} + ${#updated[@]}))
done

# -----------------------------------------------------------------------------
# Step 3: Execution Summary
# -----------------------------------------------------------------------------
echo -e "\n${COLOR_YELLOW}[3/3] Execution Summary${COLOR_RESET}"
echo -e "${COLOR_CYAN}==========================================================${COLOR_RESET}"

for i in "${!REPORT_TARGET_NAMES[@]}"; do
    echo -e "${COLOR_WHITE}Target Environment: ${REPORT_TARGET_NAMES[$i]}${COLOR_RESET}"
    echo -e "  ${COLOR_DARK_GRAY}Directory:        ${REPORT_TARGET_PATHS[$i]}${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}Skills Added:     ${REPORT_ADDED_COUNTS[$i]}${COLOR_RESET}"
    echo -e "  ${COLOR_YELLOW}Skills Updated:   ${REPORT_UPDATED_COUNTS[$i]}${COLOR_RESET}"
    echo -e "  ${COLOR_DARK_GRAY}Skills Unchanged: ${REPORT_UNCHANGED_COUNTS[$i]}${COLOR_RESET}"

    if [[ ${REPORT_ADDED_COUNTS[$i]} -gt 0 ]]; then
        echo -e "  ${COLOR_GREEN}Newly Added:      ${REPORT_ADDED_LISTS[$i]}${COLOR_RESET}"
    fi
    if [[ ${REPORT_UPDATED_COUNTS[$i]} -gt 0 ]]; then
        echo -e "  ${COLOR_YELLOW}Updated:          ${REPORT_UPDATED_LISTS[$i]}${COLOR_RESET}"
    fi
    echo -e "${COLOR_DARK_GRAY}----------------------------------------------------------${COLOR_RESET}"
done

if [[ $total_modified -eq 0 ]]; then
    echo -e "\n${COLOR_GREEN}All skills are up-to-date across all selected targets.${COLOR_RESET}"
else
    echo -e "\n${COLOR_GREEN}Synchronization complete! $total_modified skill update(s) applied.${COLOR_RESET}"
fi
