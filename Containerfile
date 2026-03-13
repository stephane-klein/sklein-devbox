FROM fedora:43

RUN dnf update -y && \
    dnf install -y \
        curl \
        git \
        wget \
        zsh \
        && \
    dnf clean all

# Install chezmoi
RUN curl -sSL https://chezmoi.io/get | sh

# Install gosu
RUN curl -sSL https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64 -o /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu

# Create user sklein with fixed UID 1000
RUN groupadd -g 1000 sklein && \
    useradd -u 1000 -g sklein -s /bin/zsh -m sklein

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Configure XDG directories
ENV XDG_CONFIG_HOME=/home/sklein/.config \
    XDG_DATA_HOME=/home/sklein/.local/share \
    XDG_CACHE_HOME=/home/sklein/.cache \
    XDG_STATE_HOME=/home/sklein/.local/state

# Create XDG directories (will be re-owned by entrypoint)
RUN mkdir -p ${XDG_CONFIG_HOME} ${XDG_DATA_HOME} ${XDG_CACHE_HOME} ${XDG_STATE_HOME}

# Set Zsh as default shell
ENV SHELL=/bin/zsh

WORKDIR /workspace/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/zsh"]
