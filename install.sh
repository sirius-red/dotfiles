#!/usr/bin/env bash

set -e

PROJECT_ROOT=$(pwd)
WORKDIR="./tmp-$$"
COLOR="purple"

install() {
	local resources_url="https://github.com/sirius-red/dotfiles/releases/download/res"

	mkdir -p "$WORKDIR"
	cd "$WORKDIR"
	trap 'cd "$PROJECT_ROOT" && rm -rf "$WORKDIR"' EXIT

	# install packages
	packages=(
		git
		curl
		p7zip
		neofetch
		zsh
		lsd
		awesome-terminal-fonts
		gnome-shell-extensions
		kvantum
		alacritty
	)
	sudo pacman -S --noconfirm --needed "${packages[@]}"

	# setup terminal
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
	echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >>"${HOME}/.zshrc"
	sudo chsh -s "$(which zsh)" "$(whoami)"

	# download and install backgrounds
	curl -LO "${resources_url}/backgrounds.7z"
	7z x ./backgrounds.7z -o ./
	cd ./backgrounds/home
	find . -exec cp -rf --parents "{}" "$HOME" \;
	cd ../system
	find . -exec sudo cp -rf --parents "{}" / \;
	cd ../..

	# install theme
	## gtk theme
	git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
	cd WhiteSur-gtk-theme
	./install.sh -l -t "$COLOR" -s 180 -i arch -m -HD --darker -b "$HOME/.local/share/backgrounds/Anime-Room.png"
	sudo ./tweaks.sh -g -c Dark -t "$COLOR" -i arch -b "$HOME/.local/share/backgrounds/Lofi-Urban-Nightscape.png"
	./tweaks.sh -d
	ln -sf "${HOME}/.config/gtk-4.0/gtk-Dark.css" "${HOME}/.config/gtk-4.0/gtk.css"
	cd ..
	## qt theme
	git clone https://github.com/vinceliuice/WhiteSur-kde.git --depth 1
	cd WhiteSur-kde
	./install.sh --sharp
	cd ..

	# install wallpaper
	git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git --depth 1
	cd WhiteSur-wallpapers
	sudo ./install-gnome-backgrounds.sh
	cd ..

	# install cursors
	git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth 1
	cd WhiteSur-cursors
	./install.sh
	cd ..

	# install icon theme
	git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth 1
	cd WhiteSur-icon-theme
	./install.sh -t "$COLOR" -a -b
	cd ..

	# copy dotfiles
	cd "${PROJECT_ROOT}/dotfiles"
	find . -exec cp -rf --parents "{}" "$HOME" \;

	# import gnome settings
	cd "$WORKDIR"
	curl -LO "${resources_url}/gnome-settings.conf"
	if [[ "$COLOR" != "purple" ]]; then
		sed -i "s/WhiteSur-Dark-purple/WhiteSur-Dark-${COLOR}/g" ./gnome-settings.conf
		sed -i "s/WhiteSur-purple-dark/WhiteSur-${COLOR}-dark/g" ./gnome-settings.conf
	fi
	dconf load -f / <./gnome-settings.conf
}

while test $# -gt 0; do
	case $1 in
	-c | --color)
		if [[ "$2" =~ blue|purple|pink|red|orange|yellow|green|grey ]]; then
			COLOR="$2"
		else
			echo "[ERROR] Invalid color: $2"
			echo "Available colors: blue | purple | pink | red | orange | yellow | green | grey"
			exit 1
		fi
		;;
	esac
done

if install; then
	echo "Installation complete, restart the system!"
else
	echo "Error during installation!"
fi
