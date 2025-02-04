FROM archlinux:base-devel

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN pacman -Syu --noconfirm; \
    pacman -S --noconfirm --needed git github-cli vim neofetch htop uv ttf-jetbrains-mono ttf-jetbrains-mono-nerd shellcheck shfmt; \
    curl -L https://sirius-red.github.io/aurbuilder/install | sh \
    && aurbuilder install -y yay-bin nvm hadolint-bin
