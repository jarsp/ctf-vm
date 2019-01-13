FROM ubuntu:16.04

RUN dpkg --add-architecture i386
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -y gdb gdbserver libc6-i386

CMD sleep infinity
