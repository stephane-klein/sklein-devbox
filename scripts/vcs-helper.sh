#!/usr/bin/env bash
set -euo pipefail

detect_vcs() {
    if [[ -d ".jj" ]]; then
        echo "jj"
    elif [[ -d ".git" ]]; then
        echo "git"
    else
        echo "unknown" >&2
        return 1
    fi
}

vcs_current_branch() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git rev-parse --abbrev-ref HEAD
            ;;
        jj)
            jj bookmark list --no-pager -r @ --list-aliases 2>/dev/null | awk '{print $1}' || \
            jj log --no-pager -r @ -T "bookmark_name()" 2>/dev/null || \
            echo "@"
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_status() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git status --porcelain
            ;;
        jj)
            jj status --no-pager 2>&1 | awk '/^Working copy changes:$/,0 {if (/^[MADRC] /) print}'
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_is_clean() {
    local vcs_status_output
    vcs_status_output=$(vcs_status)
    [[ -z "$vcs_status_output" ]]
}

vcs_current_sha() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git rev-parse --short HEAD
            ;;
        jj)
            jj log --no-pager -r @ --no-graph | awk 'NR==1 {print $1}'
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_current_full_sha() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git rev-parse HEAD
            ;;
        jj)
            jj log --no-pager -r @- -T 'commit_id' | awk 'NR==1 {print $2}'
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_latest_tag() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git describe --tags --abbrev=0 2>/dev/null || echo ""
            ;;
        jj)
            jj tag list --no-pager --sort committer-date- | head -1 | awk -F: '{print $1}' || true
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_tag_exists() {
    local tag_name="$1"
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git tag -l "$tag_name" | grep -q "^${tag_name}$"
            ;;
        jj)
            jj tag list --no-pager | grep -q "^${tag_name} "
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_create_tag() {
    local tag_name="$1"
    local message="${2:-}"
    local revision="${3:-}"
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            if [[ -n "$revision" ]]; then
                if [[ -n "$message" ]]; then
                    git tag -a "$tag_name" -m "$message" "$revision"
                else
                    git tag -a "$tag_name" "$revision"
                fi
            else
                if [[ -n "$message" ]]; then
                    git tag -a "$tag_name" -m "$message"
                else
                    git tag -a "$tag_name"
                fi
            fi
            ;;
        jj)
            if [[ -n "$revision" ]]; then
                jj tag set "$tag_name" -r "$revision"
            else
                jj tag set "$tag_name"
            fi
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_export_to_git() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            return 0
            ;;
        jj)
            jj git export
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_tag_target_commit() {
    local tag_name="$1"
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git rev-parse "$tag_name^{}"
            ;;
        jj)
            jj log --no-pager -r "$tag_name" -T 'commit_id' | awk 'NR==1 {print $2}'
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_tag_on_current_commit() {
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git describe --tags --exact-match HEAD 2>/dev/null || echo ""
            ;;
        jj)
            jj tag list --no-pager -r @ 2>/dev/null | awk '{print $1}' || echo ""
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_tags_with_prefix() {
    local prefix="$1"
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git tag -l "${prefix}*" || true
            ;;
        jj)
            jj tag list --no-pager | grep "^${prefix}" | awk '{print $1}' || true
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}

vcs_archive() {
    local ref="$1"
    local prefix="$2"
    local output="$3"
    local vcs
    vcs=$(detect_vcs)

    case "$vcs" in
        git)
            git archive --format=tar.gz --prefix="$prefix" --output="$output" "$ref"
            ;;
        jj)
            jj git export >/dev/null 2>&1
            git archive --format=tar.gz --prefix="$prefix" --output="$output" "$ref"
            ;;
        *)
            echo "Error: Unknown VCS" >&2
            return 1
            ;;
    esac
}
