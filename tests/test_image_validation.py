"""Synthetic rejection tests. The fixture is NOT a bootable kernel/image."""
import gzip, hashlib, importlib.util, stat, struct, unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location("validator",Path(__file__).parents[1]/"scripts/validate-boot.py")
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
def fdt(compatible=None):
    st=struct.pack(">I",1)+b"\0"*4;strings=b""
    if compatible:
        strings=b"compatible\0";val=compatible+b"\0"
        st+=struct.pack(">3I",3,len(val),0)+val
        st+=bytes(-len(st)%4)
    st+=struct.pack(">2I",2,9)
    return struct.pack(">10I",0xd00dfeed,56+len(st)+len(strings),56,56+len(st),40,17,16,0,len(strings),len(st))+bytes(16)+st+strings
def cpio():
    data=b""
    files={"init":b"#!/bin/sh\n","usb-gadget":b"#!/bin/sh\n",
           "bin/busybox":b"fixture","bin/blkid":b"fixture","bin/mountpoint":b"fixture","TRAILER!!!":b""}
    for i,(name,content) in enumerate(files.items()):
        name=name.encode()+b"\0"
        fields=[i,stat.S_IFREG|0o755,0,0,1,0,len(content),0,0,0,0,len(name),0]
        data+=b"070701"+b"".join(f"{n:08x}".encode() for n in fields)+name
        data+=bytes(-len(data)%4)+content
        data+=bytes(-len(data)%4)
    return data
def fixture(compatible=b"xiaomi,begonia\0mediatek,mt6785"):
    kernel=bytearray(64);kernel[56:60]=b"ARM\x64"
    empty=fdt()
    dtbo=struct.pack(">8I",0xd7b7ab1e,len(empty)+64,32,32,1,32,2048,0)+struct.pack(">8I",len(empty),64,0,0,0,0,0,0)+empty
    parts=[gzip.compress(kernel),gzip.compress(cpio()),dtbo,fdt(compatible)]
    h=bytearray(2048);h[:8]=b"ANDROID!"
    for off,n in {8:len(parts[0]),12:0x40080000,16:len(parts[1]),20:0x47c80000,32:0x4bc80000,
                  36:2048,40:2,1632:len(parts[2]),1644:1660,1648:len(parts[3])}.items():
        struct.pack_into("<I",h,off,n)
    struct.pack_into("<Q",h,1636,6144)
    struct.pack_into("<Q",h,1652,0x4bc80000)
    cmd=b"bootopt=64S3,32N2,64N2 root=LABEL=ARCHBEGONIA rw systemd.unit=multi-user.target"
    h[64:64+len(cmd)]=cmd
    sha=hashlib.sha1()
    for payload in (parts[0],parts[1],b"",parts[2],parts[3]):
        sha.update(payload);sha.update(struct.pack("<I",len(payload)))
    h[576:608]=sha.digest()+bytes(12)
    return bytes(h)+b"".join(b+bytes(-len(b)%2048) for b in parts)
class Validation(unittest.TestCase):
    def test_fixture_structure(self):
        r=v.validate(fixture())
        self.assertEqual(r["device_boot"],"UNTESTED")
        self.assertFalse(r["measured_partition_fit"])
        self.assertFalse(r["flash_authorized"])
    def test_wrong_board(self):
        with self.assertRaisesRegex(ValueError,"wrong device"): v.validate(fixture(b"realme,nemo"))
    def test_partition_too_small(self):
        with self.assertRaisesRegex(ValueError,"does not fit"): v.validate(fixture(),boot_partition_bytes=4096)
    def test_truncated_component(self):
        with self.assertRaisesRegex(ValueError,"truncated"): v.validate(fixture()[:6200])
    def test_dtbo_offset_corruption(self):
        d=bytearray(fixture());struct.pack_into("<Q",d,1636,0)
        with self.assertRaisesRegex(ValueError,"offset mismatch"): v.validate(d)
    def test_wrong_header(self):
        d=bytearray(fixture());struct.pack_into("<I",d,40,0)
        with self.assertRaisesRegex(ValueError,"header v2"): v.validate(d)
    def test_no_unchecked_trailing_data(self):
        with self.assertRaisesRegex(ValueError,"trailing"): v.validate(fixture()+bytes(4096))
    def test_missing_cpio_trailer(self):
        with self.assertRaises(ValueError): v.cpio(cpio()[:-180])
    def test_decompression_limit(self):
        with self.assertRaisesRegex(ValueError,"size limit"): v.ungzip(gzip.compress(b"a"*1000),maximum=100)
    def test_corrupted_payload(self):
        d=bytearray(fixture());d[2055]^=1
        with self.assertRaisesRegex(ValueError,"checksum mismatch"): v.validate(d)
if __name__=="__main__": unittest.main()
