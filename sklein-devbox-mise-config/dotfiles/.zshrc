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

# Completion for mise itself (subcommands, versions, tasks, ...). `mise activate`
# only wires completions for managed tools that ship one (fnox, pitchfork, ...),
# never for the `mise` command: it must be installed explicitly.
eval "$(mise completion zsh)"

# Carapace - multi-command completion engine (jj, gh, kubectl, k9s, helm, ...).
# carapace is a mise-managed tool: it must be on PATH, so load it after the
# `mise activate` block above. It overrides the built-in completions of the
# commands it covers; the ones it does not know fall back to zsh/bash.
if command -v carapace &> /dev/null; then
    export CARAPACE_BRIDGES='zsh,bash'
    zstyle ':completion:*' format $'%{\e[2;37m%}Completing %d%{\e[m%}'
    source <(carapace _carapace)
fi

# gopass has no carapace completer: use its native zsh completion.
if command -v gopass &> /dev/null; then
    source <(gopass completion zsh)
fi

# fzf-tab - replace zsh's completion menu with an fzf picker (needs the fzf
# binary, hence after `mise activate`; and after `compinit`). The plugin is
# vendored by scripts/sync-fzf-tab.sh into ~/.config/zsh/fzf-tab.
if [[ -r "$HOME/.config/zsh/fzf-tab/fzf-tab.plugin.zsh" ]]; then
    # 'menu no' lets fzf-tab capture the unambiguous prefix.
    zstyle ':completion:*' menu no
    # Enable group support in the fzf menu.
    zstyle ':completion:*:descriptions' format '[%d]'
    source "$HOME/.config/zsh/fzf-tab/fzf-tab.plugin.zsh"
fi

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

source "$HOME/.config/try-rs/try-rs.zsh"
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

# Key bindings for the editing keys, ported from oh-my-zsh's
# lib/key-bindings.zsh (this setup does not load oh-my-zsh). Stock zsh binds
# only the arrow keys: Delete/Home/End/... stay unbound and their escape
# sequence leaks a trailing '~'. Ctrl-R is intentionally left to atuin.
zmodload zsh/terminfo 2>/dev/null

# Put the terminal in application mode while ZLE is active, so the sequences
# read from $terminfo are the valid ones.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    zle-line-init()   { echoti smkx }
    zle-line-finish() { echoti rmkx }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

bindkey -e

_zsh_bind() {
    [[ -z "$1" ]] && return
    bindkey -M emacs "$1" "$2"
    bindkey -M viins "$1" "$2"
    bindkey -M vicmd "$1" "$2"
}

_zsh_bind "${terminfo[kpp]}"   up-line-or-history
_zsh_bind "${terminfo[knp]}"   down-line-or-history
_zsh_bind "${terminfo[khome]}" beginning-of-line
_zsh_bind "${terminfo[kend]}"  end-of-line
_zsh_bind "${terminfo[kcbt]}"  reverse-menu-complete
if [[ -n "${terminfo[kdch1]}" ]]; then
    _zsh_bind "${terminfo[kdch1]}" delete-char
else
    _zsh_bind '^[[3~' delete-char
fi

bindkey -M emacs '^[[1;5C' forward-word
bindkey -M viins '^[[1;5C' forward-word
bindkey -M vicmd '^[[1;5C' forward-word
bindkey -M emacs '^[[1;5D' backward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M vicmd '^[[1;5D' backward-word
bindkey -M emacs '^[[3;5~' kill-word
bindkey -M viins '^[[3;5~' kill-word
bindkey -M vicmd '^[[3;5~' kill-word

unset -f _zsh_bind

# starship must be the LAST thing that sets the prompt: keep this block at
# the end of the file, after every other prompt-affecting init.
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
