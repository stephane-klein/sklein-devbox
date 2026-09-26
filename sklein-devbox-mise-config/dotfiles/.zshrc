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

# starship must be the LAST thing that sets the prompt: keep this block at
# the end of the file, after every other prompt-affecting init.
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
