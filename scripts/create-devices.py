#!/usr/bin/env python3
"""Create minimal Linux character devices for an offline image/chroot."""
import os
from pathlib import Path
import stat
import sys

def create_devices(root):
    dev = Path(root) / 'dev'
    if dev.is_symlink():
        raise ValueError('Refusing a symlinked /dev')
    dev.mkdir(exist_ok=True)
    for name, major, minor, mode in [
        ('null', 1, 3, 0o666), ('zero', 1, 5, 0o666),
        ('random', 1, 8, 0o666), ('urandom', 1, 9, 0o666),
        ('tty', 5, 0, 0o666), ('console', 5, 1, 0o600),
    ]:
        path = dev / name
        device = os.makedev(major, minor)
        try:
            info = path.lstat()
        except FileNotFoundError:
            os.mknod(path, stat.S_IFCHR | mode, device)
        else:
            if not stat.S_ISCHR(info.st_mode) or info.st_rdev != device:
                raise ValueError(f'Refusing unexpected device entry: {path}')
        path.chmod(mode)

if __name__ == '__main__':
    create_devices(sys.argv[1])
