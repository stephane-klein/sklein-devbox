FROM fedora:43

RUN dnf update -y && \
    dnf install -y \
        curl \
        git \
        wget \
        zsh \
        neovim \
        ripgrep \
        fd-find \
        fzf \
        tmux \
        && \
    dnf clean all

# Install Mise (https://mise.jdx.dev/)
RUN curl https://mise.run | sh && \
    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

# Set Zsh as default shell
ENV SHELL=/bin/zsh

WORKDIR /workspace

CMD ["/bin/zsh"]
