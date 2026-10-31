#!/usr/bin/env python3
"""Reproduce OpenSSH's missing-/dev/null failure, then test the fix."""
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

spec = importlib.util.spec_from_file_location('devices', Path(__file__).with_name('create-devices.py'))
devices = importlib.util.module_from_spec(spec)
spec.loader.exec_module(devices)
assert os.geteuid() == 0, 'Run with sudo on the CI runner'
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    binary = Path(shutil.which('ssh-keygen'))
    libraries = subprocess.check_output(['ldd', str(binary)], text=True)
    for source in [str(binary), *re.findall(r'/[^\s()]+', libraries)]:
        target = root / source.lstrip('/')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        target.chmod(0o755)
    command = ['chroot', str(root), str(binary), '-q', '-t', 'ed25519', '-N', '', '-f', '/test-key']
    before = subprocess.run(command, capture_output=True, text=True)
    assert before.returncode != 0 and '/dev/null' in before.stderr, before.stderr
    devices.create_devices(root)
    devices.create_devices(root)  # Idempotent; preserve the same character nodes.
    with (root/'dev/null').open('wb') as null:
        null.write(b'null-device-test')
    with (root/'dev/urandom').open('rb') as random:
        assert len(random.read(32)) == 32
    after = subprocess.run(command, capture_output=True, text=True)
    assert after.returncode == 0, after.stderr
    assert (root/'test-key.pub').read_text().startswith('ssh-ed25519 ')
print('PASS: reproduced missing /dev/null; key generation succeeds with real character devices')
