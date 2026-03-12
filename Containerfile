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

# Create user sklein
RUN groupadd -r sklein && \
    useradd -r -g sklein -s /bin/zsh -m sklein

# Configure XDG directories
ENV XDG_CONFIG_HOME=/home/sklein/.config \
    XDG_DATA_HOME=/home/sklein/.local/share \
    XDG_CACHE_HOME=/home/sklein/.cache \
    XDG_STATE_HOME=/home/sklein/.local/state

# Switch to sklein user
USER sklein

# Create XDG directories with correct ownership
RUN mkdir -p ${XDG_CONFIG_HOME} ${XDG_DATA_HOME} ${XDG_CACHE_HOME} ${XDG_STATE_HOME}
RUN curl https://mise.run | sh && \
    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

# Set Zsh as default shell
ENV SHELL=/bin/zsh

WORKDIR /home/sklein

CMD ["/bin/zsh"]
