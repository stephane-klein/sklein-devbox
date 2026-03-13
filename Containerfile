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

# Install Starship in /usr/local/bin
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir /usr/local/bin

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

# Install OhMyZsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install OhMyZsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Configure OhMyZsh: disable theme (Starship will handle prompt) and add plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME=""/' ~/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Enable Starship (after OhMyZsh init)
RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# Pre-generate zsh caches to avoid first-launch delay
RUN zsh -c 'exit'

# Set Zsh as default shell
ENV SHELL=/bin/zsh

WORKDIR /home/sklein

CMD ["/bin/zsh"]
