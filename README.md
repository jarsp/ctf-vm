# ctf-vm

Simple scripts for my ctf setup.

Clone the repo and run with ./setup.sh INSTALL\_DIR inside the VM to install into the given directory as the current user.

An Ubuntu VM is required, probably 16.04 at least.

Tested on:
- 18.04

## Install List

The following items are installed, listed with their dependencies (that are found in the file):

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
- wine-development (currently not from ppa, appears to be broken)

### Personal
- compton
- dmenu
- feh
- fasd
- fzf
- neovim: python2/3-dev
    - vim-plug
    - vim-easymotion
- st
    - LukeSmithxyz/st fork
    - Slightly modified theme
- xmonad: ghc, libx11-dev, libghc-xmonad-dev, libghc-xmonad-contrib-dev
- xmobar
- zsh
    - antigen
    - oh-my-zsh
    - subnixr/minimal theme
