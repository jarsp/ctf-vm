#!/bin/bash

if [ "$#" -ne 1 ]
then
    echo "Usage: $0 INSTALL_DIR"
    exit 1
fi

INSTALL_DIR="$1"

REPO_DIR="$(pwd)"
REPO_CONFIG_DIR="${REPO_DIR}/configs"

VENV_DIR="${INSTALL_DIR}/venvs"
CLONE_DIR="${INSTALL_DIR}/repos"
SCRIPTS_DIR="${INSTALL_DIR}/scripts"

DEFAULT_VENV="ctf"

UBUNTU_RELEASE="$(lsb_release -cs)"
USER="$(whoami)"

CLEANUP_ARRAY=()

# Setup
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

mkdir -p "${VENV_DIR}"
mkdir -p "${CLONE_DIR}"

# Fill in templates
for f in $(ls -a "${REPO_CONFIG_DIR}")
do
    if [ "$f" != "." -a "$f" != ".." ]
    then
        sed -e "s&__INSTALL__DIR__&${INSTALL_DIR}&g" "${REPO_CONFIG_DIR}/$f" | \
        sed -e "s&__REPO__DIR__&${REPO_DIR}&g" | \
        sed -e "s&__REPO_CONFIG_DIR__&${REPO_CONFIG_DIR}&g" | \
        sed -e "s&__VENV_DIR__&${VENV_DIR}&g" | \
        sed -e "s&__CLONE_DIR__&${CLONE_DIR}&g" | \
        sed -e "s&__SCRIPTS_DIR__&${SCRIPTS_DIR}&g" | \
        sed -e "s&__DEFAULT_VENV__&${DEFAULT_VENV}&g" | \
        sed -e "s&__USER__&${USER}&g" > "${REPO_CONFIG_DIR}/${f%.*}"
        CLEANUP_ARRAY+="${REPO_CONFIG_DIR}/${f%.*}"
    fi
done

###### PACKAGE INSTALLATION ######

# Add arch
sudo dpkg --add-architecture i386

# For postfix, wtf sagemath
export DEBIAN_FRONTEND=noninteractive
sudo debconf-set-selections <<< "postfix postfix/mailname string ubuntu"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# Install packages (if using an 'older' version of Ubuntu modify
# Neovim packages accordingly https://github.com/neovim/neovim/wiki/Installing-Neovim)
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    libc6-i386 \
    libmpfr-dev \
    libmpc-dev \
    libvirt-bin \
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
    virtualenv

# Docker PPA
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   ${UBUNTU_RELEASE}\
   stable"

# Wine PPA (necessary to avoid bugs with python installer in wine)
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo apt-add-repository -y \
    "deb https://dl.winehq.org/wine-builds/ubuntu/ \
    $(lsb_release -cs) \
    main"

# Install PPA stuff
sudo apt-get update
sudo apt-get install -y \
    docker-ce
sudo apt-get install --install-recommends -y winehq-staging

# RVM/Ruby install
sudo apt-get update
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable --rails


###### PYTHON(2) VENV SETUP ######

# Venv creation
cd ${INSTALL_DIR}
virtualenv -p $(which python) venvs/ctf
source venvs/ctf/bin/activate

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

# pwndbg
cd "${CLONE_DIR}"
git clone https://github.com/pwndbg/pwndbg
cd pwndbg
./setup.sh

# pwngdb
cd "${CLONE_DIR}"
git clone https://github.com/scwuaptx/Pwngdb.git

# Make pwndbg and pwngdb play nice
cp "${REPO_CONFIG_DIR}/.gdbinit" ~/.gdbinit

# radare2
cd "${CLONE_DIR}"
git clone https://github.com/radare/radare2
cd radare2
sys/install.sh

# r2 config
cp ${REPO_CONFIG_DIR}/.radare2rc ~/.radare2rc

###### PERSONAL PREFS ######

# Package installation
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install -y \
    neovim \
    zsh

# fasd
cd "${REPO_DIR}"
git clone https://github.com/clvv/fasd
cd fasd
sudo make install

# fzf
cd "${REPO_DIR}"
git clone https://github.com/junegunn/fzf
./fzf/install --key-bindings --completion --update-rc

# vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


###### PERSONAL CONFIGS ######

# Neovim config
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --config vi
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --config vim
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
sudo update-alternatives --config editor

mkdir -p ~/.config/nvim
cp "${REPO_CONFIG_DIR}/init.vim" ~/.config/nvim/init.vim
vi -c ":PlugInstall | :qa!"

# Zsh config, oh-my-zsh, antigen
sudo chsh -s $(which zsh)
rm ~/.zshrc # annoying

sh -c $(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d' | sed "s/chsh -s/#chsh -s/")

curl -L git.io/antigen > ~/.config/antigen.zsh
cp "${REPO_CONFIG_DIR}/.zshrc" ~/.zshrc


###### CLEANUP ######

# Delete temp files
for f in "$CLEANUP_ARRAY[@]"
do
    rm -f "$f"
done
