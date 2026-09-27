#!/usr/bin/env bash
# ~/bin/install-or-update-neovim.sh

echo "Install Lazy packages..."
nvim --headless "+Lazy! restore" +qa
echo -e "...Lazy packages installation done\n"

echo "Install Mason packages..."
nvim --headless -c "MasonToolsInstallSync" +qa
echo -e "...Mason installation done\n"

echo "Install TreeSitter packages..."
nvim --headless -c "luafile ~/.config/nvim/lua/config/install-treesitter-parsers.lua" +qa
echo -e "...TreeSitter installation done\n"
