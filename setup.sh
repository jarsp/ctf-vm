#!/bin/bash

# Prevent sudo timeout
# https://serverfault.com/questions/266039/temporarily-increasing-sudos-timeout-for-the-duration-of-an-install-script
sudo -v # ask for sudo password up-front
while true; do
  # Update user's timestamp without running a command
  sudo -nv; sleep 1m
  # Exit when the parent process is not running any more. In fact this loop
  # would be killed anyway after being an orphan(when the parent process
  # exits). But this ensures that and probably exit sooner.
  kill -0 $$ 2>/dev/null || exit
done &

set -x

if [[ "$#" -ne 1 ]]
then
    echo "Usage: $0 INSTALL_DIR"
    exit 1
fi

mkdir -p "$1"
INSTALL_DIR="$(cd $1 && pwd)"

REPO_DIR="$(dirname $0)"
REPO_DIR="$(cd ${REPO_DIR} && pwd)"

REPO_CONFIG_DIR="${REPO_DIR}/configs"
REPO_SCRIPTS_DIR="${REPO_DIR}/scripts"

VENV_DIR="${INSTALL_DIR}/venvs"
CLONE_DIR="${INSTALL_DIR}/repos"
SCRIPTS_DIR="${INSTALL_DIR}/scripts"

DEFAULT_VENV="ctf"

UBUNTU_RELEASE="$(lsb_release -cs)"
USER="$(whoami)"

CLEANUP_ARRAY=()

# Setup
cd "${INSTALL_DIR}"

mkdir -p "${VENV_DIR}"
mkdir -p "${CLONE_DIR}"

# Fill in templates
for f in $(find "${REPO_DIR}" -name '*.template' -type f)
do
    sed -e "s&__INSTALL_DIR__&${INSTALL_DIR}&g" \
        -e "s&__REPO__DIR__&${REPO_DIR}&g" \
        -e "s&__REPO_CONFIG_DIR__&${REPO_CONFIG_DIR}&g" \
        -e "s&__REPO_SCRIPTS_DIR__&${REPO_SCRIPTS_DIR}&g" \
        -e "s&__VENV_DIR__&${VENV_DIR}&g" \
        -e "s&__CLONE_DIR__&${CLONE_DIR}&g" \
        -e "s&__SCRIPTS_DIR__&${SCRIPTS_DIR}&g" \
        -e "s&__DEFAULT_VENV__&${DEFAULT_VENV}&g" \
        -e "s&__USER__&${USER}&g" "$f" > "${f%.*}"
    CLEANUP_ARRAY+=("${f%.*}")
done

# Copy scripts
mkdir -p "${SCRIPTS_DIR}"
cp -r "${REPO_SCRIPTS_DIR}"/* "${SCRIPTS_DIR}/"
find "${SCRIPTS_DIR}" -name '*.template' -type f | xargs rm -f
chmod a+x "${SCRIPTS_DIR}"/*

###### PACKAGE INSTALLATION ######

# Add arch
sudo dpkg --add-architecture i386

# For postfix, wtf sagemath
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< "postfix postfix/mailname string ubuntu"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# Install packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    apt-transport-https \
    bison \
    build-essential \
    ca-certificates \
    curl \
    flex \
    expat \
    git \
    gnupg2 \
    libc6-i386 \
    libmpfr-dev \
    libmpc-dev \
    libvirt-bin \
    m4 \
    python \
    python-dev \
    python-pip \
    python3 \
    python3-dev \
    python3-pip \
    qemu \
    qemu-kvm \
    sagemath \
    software-properties-common \
    texinfo \
    virtualenv

# Disable postfix lol
sudo service postfix stop
sudo systemctl disable postfix

# Docker PPA
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   ${UBUNTU_RELEASE}\
   stable"

# Wine PPA (necessary to avoid bugs with python installer in wine)
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo apt-add-repository -y \
    "deb https://dl.winehq.org/wine-builds/ubuntu/${UBUNTU_RELEASE} main"

# Install PPA stuff
sudo apt-get update
sudo apt-get install -y \
    docker-ce
sudo apt-get install --install-recommends -y winehq-staging

# Run docker as user
sudo groupadd -f docker
sudo usermod -aG docker "${USER}"

# RVM/Ruby install
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable --rails


###### PYTHON(2) VENV SETUP ######

# Venv creation
cd "${INSTALL_DIR}"
virtualenv -p $(which python) "venvs/${DEFAULT_VENV}"
source "venvs/${DEFAULT_VENV}/bin/activate"

# Packages 
pip install \
    flask \
    gmpy \
    gmpy2 \
    ipython \
    numpy \
    pwntools \
    pycryptodome


###### OTHER INSTALLS ######

# one_gadget (have had issues installing after pwndbg, leave in front)
source ~/.rvm/scripts/rvm
gem install one_gadget

# GDB rebuild (cause distro python is so broken)
# Technically I can hack around it but this is cleaner
deactivate
cd "${VENV_DIR}"
virtualenv -p "$(which python3)" gdb-python
source "${VENV_DIR}/gdb-python/bin/activate"
cd "${CLONE_DIR}"
git clone git://sourceware.org/git/binutils-gdb.git
mkdir -p gdb-build
cd binutils-gdb
./configure --prefix="${CLONE_DIR}/gdb-build/" --with-python="${VENV_DIR}/gdb-python/bin/"
make
make install

# pwndbg
cd "${CLONE_DIR}"
git clone https://github.com/pwndbg/pwndbg
cd pwndbg
# install required packages to python3 venv
pip install -Ur requirements.txt

# pwngdb
cd "${CLONE_DIR}"
git clone https://github.com/scwuaptx/Pwngdb.git

# Make pwndbg and pwngdb play nice
cp "${REPO_CONFIG_DIR}/.gdbinit" ~/.gdbinit
deactivate
source "${VENV_DIR}/${DEFAULT_VENV}/bin/activate"

# radare2
cd "${CLONE_DIR}"
git clone https://github.com/radare/radare2
cd radare2
sys/install.sh

# r2 config
cp "${REPO_CONFIG_DIR}/.radare2rc" ~/.radare2rc

###### PERSONAL PREFS ######

# Package installation
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install -y \
    compton \
    dmenu \
    feh \
    fontconfig \
    ghc \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libxft-dev \
    libghc-xmonad-dev \
    libghc-xmonad-contrib-dev \
    neovim \
    pkg-config \
    x11proto-core-dev \
    xmobar \
    xmonad \
    zsh

# Antigen
curl -L git.io/antigen > ~/.config/antigen.zsh

# fasd
cd "${CLONE_DIR}"
git clone https://github.com/clvv/fasd
cd fasd
sudo make install

# fzf
cd "${CLONE_DIR}"
git clone https://github.com/junegunn/fzf
./fzf/install --key-bindings --completion --update-rc

# Oh-my-zsh
sudo chsh -s "$(which zsh)" "${USER}"
rm ~/.zshrc # annoying

sh -c $(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d' | sed "s/chsh -s/#chsh -s/")

# st
cd "${CLONE_DIR}"
git clone https://github.com/LukeSmithxyz/st
cd st
sed -i \
    -e "s/unsigned int alpha = 0xed/unsigned int alpha = 0x80/g" \
    -e "s/282828/000000/g" config.h
sudo make clean install
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/st 60

# Vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


###### PERSONAL CONFIGS ######

# Bg for feh
cp "${REPO_DIR}/nu_composite.png" "${INSTALL_DIR}/wallpaper.png"

# Neovim config
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60

mkdir -p ~/.config/nvim
cp "${REPO_CONFIG_DIR}/init.vim" ~/.config/nvim/init.vim
vi -c ":PlugInstall | :qa!"

# XMonad config
mkdir -p ~/.xmonad
cp "${REPO_CONFIG_DIR}/xmonad.hs" ~/.xmonad/xmonad.hs
cp "${REPO_CONFIG_DIR}/.xmobarrc-0" ~/.xmobarrc-0
cp "${REPO_CONFIG_DIR}/.xmobarrc-1" ~/.xmobarrc-1

# Zsh config, oh-my-zsh, antigen
cp "${REPO_CONFIG_DIR}/.zshrc" ~/.zshrc


###### CLEANUP ######

# Delete temp files
for f in "${CLEANUP_ARRAY[@]}"
do
    rm -f "$f"
done

echo "Install complete. The system needs to be rebooted."
read -p "Press enter to continue."
sudo shutdown -r now
