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

