autoload -U compinit
compinit

#allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# `mise activate` prepends the mise shims dir to PATH at eval time.
# Any mise-managed tool (starship, fzf, ...) must therefore be called
# AFTER the mise:activate block below.
# >>> mise:activate >>> managed by mise — do not edit between markers
eval "$(mise activate zsh)"
# <<< mise:activate <<<

# Atuin - advanced history with pwd, duration, and context
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# zoxide - smarter cd
eval "$(zoxide init zsh)"

# Tab-completion: list every known directory (overrides zoxide's default
# completion, which only offers local sub-directories / fuzzy search).
_z() {
    local -a dirs
    dirs=(${(f)"$(zoxide query --list 2>/dev/null)"})
    _describe 'zoxide directory' dirs
}
compdef _z z

# Refresh the tmux status bar after each command, and keep the pane title in
# sync with the current directory (the tmux status bar and the choose-window
# popup rely on it).
_tmux_refresh() {
    [[ -n "$TMUX" ]] && tmux refresh-client -S 2>/dev/null
}
precmd_functions+=( _tmux_refresh )

chpwd() {
    tmux select-pane -t "$TMUX_PANE" -T "$PWD" 2>/dev/null
}
if [[ -n "$TMUX_PANE" ]]; then
    tmux select-pane -t "$TMUX_PANE" -T "$PWD"
fi

# Yazi integration
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# try-rs integration
alias try="try-rs"

source '~/.config/try-rs/try-rs.zsh'
# try-rs tab completion for directory names
_try_rs_get_tries_path() {
    # Check TRY_PATH environment variable first
    if [[ -n "${TRY_PATH}" ]]; then
        if [[ "${TRY_PATH}" == *","* ]]; then
            echo "${TRY_PATH}" | tr ',' '\n'
        else
            echo "${TRY_PATH}"
        fi
        return
    fi
    
    # Try to read from config file
    local config_paths=("$HOME/.config/try-rs/config.toml" "$HOME/.try-rs/config.toml")
    for config_path in "${config_paths[@]}"; do
        if [[ -f "$config_path" ]]; then
            # Try tries_path (supports single or multiple paths with comma)
            local tries_path=$(grep -E '^[[:space:]]*tries_path[[:space:]]*=' "$config_path" 2>/dev/null | sed -E 's/.*=[[:space:]]*"?([^"]*)"?.*/\1/' | sed "s|~|$HOME|" | tr -d '[:space:]')
            if [[ -n "$tries_path" ]]; then
                if [[ "$tries_path" == *","* ]]; then
                    echo "$tries_path" | tr ',' '\n'
                else
                    echo "$tries_path"
                fi
                return
            fi
        fi
    done
    
    # Default path
    echo "$HOME/work/tries"
}

_try_rs_complete() {
    local -a dirs=()
    local tries_path

    while IFS= read -r tries_path; do
        if [[ -d "$tries_path" ]]; then
            local -a entries=("$tries_path"/*(N-/))
            dirs+=("${entries[@]:t}")
        fi
    done < <(_try_rs_get_tries_path)

    compadd -a dirs
}

compdef _try_rs_complete try-rs

# starship must be the LAST thing that sets the prompt: keep this block at
# the end of the file, after every other prompt-affecting init.
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
