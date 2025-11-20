# Zsh configuration
# TODO: Add your Zsh configuration here

# Enable starship prompt if available
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

