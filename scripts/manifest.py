#!/usr/bin/env python3
import hashlib,json,platform,subprocess
from pathlib import Path
out=Path("out")
def command(args):
    p=subprocess.run(args,text=True,capture_output=True)
    return p.stdout.strip() or p.stderr.strip()
m={"status":"BUILT_NOT_DEVICE_TESTED","rootfs_input_sha256":Path("inputs/SHA256SUMS").read_text().split()[0],
   "kernel_release":(out/"kernel.release").read_text().strip(),
   "sources":json.loads(Path("config/sources.json").read_text()),
   "host":platform.platform(),"clang":command(["clang","--version"]),
   "host_packages":command(["dpkg-query","-W"]),
   "build_commit":command(["git","rev-parse","HEAD"]),
   "real_device_acceptance":False,
   "reproducibility":"Pinned kernel and config; retained rootfs input. Host packages, filesystem UUID/times and compression tooling are recorded but not bit-reproducibly pinned."}
(out/"build-metadata.json").write_text(json.dumps(m,indent=2)+"\n")
