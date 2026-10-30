#!/usr/bin/env python3
"""Cross-check validator with independently implemented mkbootimg.
Only temporary synthetic images are produced; none may be flashed.
"""
import os, shlex, struct, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"tests"))
import test_image_validation as t
b=t.fixture()
sizes=[struct.unpack_from("<I",b,o)[0] for o in (8,16,1632,1648)]
with tempfile.TemporaryDirectory() as tmp:
    p=Path(tmp);offset=2048
    for name,size in zip(("Image.gz","initramfs.cpio.gz","empty.dtbo","begonia.dtb"),sizes):
        (p/name).write_bytes(b[offset:offset+size]);offset+=(size+2047)//2048*2048
    cmd=shlex.split(os.environ.get("MKBOOTIMG","mkbootimg"))
    cmd+=["--header_version","2","--base","0x40078000","--kernel_offset","0x8000",
          "--ramdisk_offset","0x07c08000","--second_offset","0xbff88000",
          "--tags_offset","0x0bc08000","--dtb_offset","0x0bc08000","--pagesize","2048",
          "--kernel",str(p/"Image.gz"),"--ramdisk",str(p/"initramfs.cpio.gz"),
          "--recovery_dtbo",str(p/"empty.dtbo"),"--dtb",str(p/"begonia.dtb"),
          "--cmdline","bootopt=64S3,32N2,64N2 root=LABEL=ARCHBEGONIA rw systemd.unit=multi-user.target",
          "--output",str(p/"test.img")]
    subprocess.run(cmd,check=True)
    result=t.v.validate((p/"test.img").read_bytes(),p)
    assert result["structural_validation"]=="passed"
print("PASS: independent mkbootimg packaging and embedded component equality; no hardware tested")
