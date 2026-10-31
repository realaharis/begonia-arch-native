import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/download-rootfs.sh'

class RootfsDownload(unittest.TestCase):
    def run_download(self, modes, digest='', override=''):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for name in ['scripts', 'config', 'bin']:
                (root/name).mkdir()
            shutil.copy(SCRIPT, root/'scripts/download-rootfs.sh')
            urls = ['https://test.invalid/'+m for m in modes]
            (root/'config/sources.json').write_text(json.dumps({'rootfs': {'url': urls[0], 'fallback_urls': urls[1:]}}))
            payload = gzip.compress(b'rootfs fixture', mtime=0)
            (root/'fixture.gz').write_bytes(payload)
            curl = root/'bin/curl'
            curl.write_text('''#!/usr/bin/env python3
import sys, pathlib
args=sys.argv[1:]
assert args[args.index('--proto')+1]=='=https'
assert args[args.index('--proto-redir')+1]=='=https'
assert '--insecure' not in args and '-k' not in args
url=next(a for a in args if a.startswith('https://'))
with open('calls','a') as f: f.write(url+'\\n')
out=pathlib.Path(args[args.index('-o')+1])
if url.endswith('tls-error'):
 out.write_bytes(b'partial'); sys.exit(60)
out.write_bytes(b'not gzip' if url.endswith('corrupt') else pathlib.Path('fixture.gz').read_bytes())
print(url)
''')
            curl.chmod(0o755)
            env = dict(os.environ, PATH=str(root/'bin')+':'+os.environ['PATH'], ROOTFS_SHA256=digest, ROOTFS_URL=override)
            result = subprocess.run(['bash', str(root/'scripts/download-rootfs.sh')], env=env, capture_output=True)
            final=root/'inputs/ArchLinuxARM-aarch64.tar.gz'
            return result.returncode, final.read_bytes() if final.exists() else None, (root/'calls').read_text().splitlines(), (root/'inputs/rootfs.download').exists()

    def test_tls_and_corrupt_fallback(self):
        code, data, calls, partial = self.run_download(['tls-error', 'corrupt', 'ok'])
        self.assertEqual(code, 0)
        self.assertEqual(gzip.decompress(data), b'rootfs fixture')
        self.assertEqual(len(calls), 3)
        self.assertFalse(partial)

    def test_digest_mismatch_rejected(self):
        code, data, _, partial = self.run_download(['ok'], '0'*64)
        self.assertNotEqual(code, 0)
        self.assertIsNone(data)
        self.assertFalse(partial)

    def test_override_does_not_fallback(self):
        code, data, calls, _ = self.run_download(['ok'], override='https://test.invalid/tls-error')
        self.assertNotEqual(code, 0)
        self.assertIsNone(data)
        self.assertEqual(len(calls), 1)

    def test_matching_digest(self):
        digest=hashlib.sha256(gzip.compress(b'rootfs fixture', mtime=0)).hexdigest()
        self.assertEqual(self.run_download(['ok'], digest)[0], 0)
