from pwn import *

import subprocess
import re

# change if needed
TERM_EMULATOR_RUN='st'

# run program in docker
# env should be shell escaped?
def process_d(cont, exe, env=None):
    cmd = ['docker', 'exec', '-i']
    if env is not None:
        for k, v in env.items():
            cmd += ['-e', '{}={}'.format(k, v)]
    cmd += [cont, exe]
    return process(cmd)

# pre-exploit, fetch program pid for later
def pre_exploit_d(cont, exe):
    pid = None
    while pid is None:
        o = subprocess.check_output(['docker', 'exec', cont, 'ps', '-ax']).split('\n')
        for l in o:
            m = re.match('\s*(\d+).*' + exe, l)
            if m is not None:
                pid = int(m.group(1))
                break
        else:
            sleep(1)
    return {'pid': pid}

# gdb.attach replacement
def make_gdb_attach_d(cont, info):
    def f(r):
        FNULL = open('/dev/null', 'w+')
        subprocess.Popen(['docker', 'exec', cont,
                          'gdbserver', '--once', '--attach', ':2345', str(info['pid'])],
                         stdin=FNULL, stdout=FNULL, stderr=FNULL)
        subprocess.Popen(TERM_EMULATOR_RUN.split() + ['gdb', '-ex', 'target remote :2345'])
    return f

# post-exploit cleanup, kill running program
def post_exploit_d(cont, info):
    subprocess.call(['docker', 'exec', cont, 'kill', '-9', str(info['pid'])])
