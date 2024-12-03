#!/usr/bin/env bash
ARCH=$(uname -m)
cd /nvim

if [ "$ARCH" = "aarch64" ]; then
	#I dont remember anymore why i was not using the version from the distro, but I don't have the energy to check
	apt update 
	apt install neovim -y
	ln -s /bin/nvim /bin/nv
else

	wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.tar.gz
	tar -xvf nvim-linux64.tar.gz

	chmod a+x /nvim/nvim-linux64/bin/nvim
	ln -s /nvim/nvim-linux64/bin/nvim /bin/nv
fi

nv +PlugUpdate +qall



