# ctf-vm

Simple scripts for my ctf setup.

Clone the repo and run with ./setup.sh INSTALL\_DIR inside the VM to install into the given directory as the current user. Please don't use any weird path names/usernames, it might be broken, but I tried.

An Ubuntu VM is required, probably 16.04 at least.

Tested on:
- 18.04

## Install List

A bunch of helper scripts are installed to INSTALL\_DIR/scripts.

Additionally the following items are installed, listed with their dependencies (that are found in the file):

### Critical
- build-essential 
- curl
- docker: apt-transport-https, ca-certificates, software-properties-common
- gdb: bison, flex, expat, libmpfr-dev, m4
- git
- libc6-i386 libraries
- one\_gadget: ruby
- pwndbg
- pwngdb
- python2/3, with -dev and -pip
- python2 packages
    - flask
    - gmpy
    - gmpy2: libmpfr-dev libmpc-dev
    - ipython
    - numpy
    - pwntools
    - pycryptodome
- RVM/ruby: gnupg2
- radare2
- sagemath
- virtualenv
- qemu: qemu-kvm libvirt-bin
- wine-development (from ppa)

### Personal
- compton
- dmenu
- feh
- fasd
- fzf
- neovim: python2/3-dev
    - vim-plug
    - vim-easymotion
- st: libx11-dev libxft-dev libfontconfig1-dev pkg-config
    - LukeSmithxyz/st fork
    - Slightly modified theme
- xmonad: ghc, libx11-dev, libghc-xmonad-dev, libghc-xmonad-contrib-dev
- xmobar
- zsh
    - antigen
    - oh-my-zsh
    - subnixr/minimal theme
