#!/usr/bin/env python3
"""Structural checks only: never evidence of real-device boot success."""
import argparse
import gzip
import hashlib
import io
import json
import stat
import struct
from pathlib import Path

def need(ok, message):
    if not ok:
        raise ValueError(message)

def ungzip(data, maximum=256*1024*1024):
    with gzip.GzipFile(fileobj=io.BytesIO(data)) as f:
        result=f.read(maximum+1)
    need(len(result)<=maximum, "decompression size limit exceeded")
    return result

def fdt(data):
    need(len(data)>=40, "truncated FDT")
    magic,total,off_st,off_str,off_mem,version,last,cpuid,str_size,st_size=struct.unpack_from(">10I",data)
    need(magic==0xd00dfeed and total==len(data), "bad FDT magic or total size")
    need(version>=17 and last<=17, "unsupported FDT version")
    need(off_st+st_size<=total and off_str+str_size<=total, "FDT blocks out of range")
    need(off_mem+16<=total and off_mem%8==0, "bad reservation offset")
    strings=data[off_str:off_str+str_size]
    pos=off_st;end=off_st+st_size;stack=[];props={};finished=False
    while pos+4<=end:
        token=struct.unpack_from(">I",data,pos)[0];pos+=4
        if token==1:
            nul=data.find(b"\0",pos,end)
            need(nul>=0, "unterminated FDT node")
            stack.append(data[pos:nul].decode())
            pos=(nul+4)&~3
        elif token==2:
            need(bool(stack),"unbalanced FDT node")
            stack.pop()
        elif token==3:
            need(pos+8<=end and stack,"bad FDT property")
            size,nameoff=struct.unpack_from(">2I",data,pos);pos+=8
            need(nameoff<len(strings) and pos+size<=end,"FDT property outside block")
            nul=strings.find(b"\0",nameoff)
            need(nul>=0,"unterminated FDT property name")
            name=strings[nameoff:nul].decode()
            props[("/".join(stack),name)]=data[pos:pos+size]
            pos=(pos+size+3)&~3
        elif token==4:
            pass
        elif token==9:
            need(not stack, "unclosed FDT nodes")
            finished=True;break
        else:
            raise ValueError("unknown FDT token")
    need(finished, "FDT missing END")
    return props

def cpio(data):
    pos=0;entries={};trailer=False
    while pos+110<=len(data):
        need(data[pos:pos+6]==b"070701","expected cpio newc")
        val=[int(data[pos+6+i*8:pos+14+i*8],16) for i in range(13)]
        mode,size,namesize=val[1],val[6],val[11];pos+=110
        need(1<=namesize<=4096 and pos+namesize<=len(data),"invalid cpio name size")
        namebytes=data[pos:pos+namesize]
        need(namebytes[-1:]==b"\0","cpio name not terminated")
        name=namebytes[:-1].decode();pos=(pos+namesize+3)&~3
        need(pos+size<=len(data),"truncated cpio payload")
        payload=data[pos:pos+size];pos=(pos+size+3)&~3
        if name=="TRAILER!!!":
            trailer=True;break
        need(not name.startswith("/") and ".." not in Path(name).parts,"unsafe cpio path")
        name=name.removeprefix("./")
        need(name not in entries,"duplicate cpio path")
        entries[name]=(mode,payload)
    need(trailer, "cpio missing trailer")
    return entries

def validate(data, components=None, boot_partition_bytes=None):
    need(len(data)>=1660 and data[:8]==b"ANDROID!","bad/truncated Android header")
    u32=lambda o:struct.unpack_from("<I",data,o)[0]
    u64=lambda o:struct.unpack_from("<Q",data,o)[0]
    need(u32(40)==2 and u32(1644)==1660,"expected header v2, size 1660")
    page=u32(36)
    need(page==2048,"unexpected page size")
    for off,want in [(12,0x40080000),(20,0x47c80000),(28,0),(32,0x4bc80000)]:
        need(u32(off)==want,f"unexpected load address at {off}")
    need(u64(1652)==0x4bc80000,"unexpected DTB load address")
    need(u32(24)==0,"unexpected second-stage payload")
    need(len(data)<=64*1024*1024,"exceeds provisional 64 MiB budget")
    if boot_partition_bytes is not None:
        need(boot_partition_bytes>0 and len(data)<=boot_partition_bytes,"does not fit measured boot partition")
    sizes=[u32(8),u32(16),u32(1632),u32(1648)]
    need(all(sizes),"empty boot component")
    sections={};pos=page
    for name,size in zip(("kernel","ramdisk","recovery_dtbo","dtb"),sizes):
        need(pos+size<=len(data),f"truncated {name}")
        if name=="recovery_dtbo":
            need(u64(1636)==pos,"recovery DTBO offset mismatch")
        sections[name]=data[pos:pos+size]
        pos+=(size+page-1)//page*page
    need(pos==len(data),"unexpected trailing bytes or missing padding (AVB not handled)")
    sha=hashlib.sha1()
    for payload in (sections["kernel"],sections["ramdisk"],b"",sections["recovery_dtbo"],sections["dtb"]):
        sha.update(payload);sha.update(struct.pack("<I",len(payload)))
    need(data[576:608]==sha.digest()+bytes(12),"Android image ID checksum mismatch")
    cmd=(data[64:576].rstrip(b"\0")+data[608:1632].rstrip(b"\0")).decode()
    for required in ("bootopt=64S3,32N2,64N2","root=LABEL=ARCHBEGONIA","rw","systemd.unit=multi-user.target"):
        need(required in cmd.split(),f"missing command-line token {required}")
    image=ungzip(sections["kernel"])
    need(len(image)>=64 and image[56:60]==b"ARM\x64","not an ARM64 Linux Image")
    props=fdt(sections["dtb"])
    compat=props.get(("","compatible"),b"").split(b"\0")
    need(b"xiaomi,begonia" in compat and b"mediatek,mt6785" in compat,"wrong device DTB")
    dtbo=sections["recovery_dtbo"]
    need(len(dtbo)>=64,"short DTBO container")
    need(struct.unpack_from(">8I",dtbo)==(0xd7b7ab1e,len(dtbo),32,32,1,32,2048,0),"invalid DTBO header")
    size,off,*reserved=struct.unpack_from(">8I",dtbo,32)
    need(off==64 and off+size==len(dtbo) and not any(reserved),"invalid DTBO entry")
    need(not fdt(dtbo[off:]),"recovery DTBO not empty")
    entries=cpio(ungzip(sections["ramdisk"]))
    for name in ("init","usb-gadget","bin/busybox","bin/blkid","bin/mountpoint","bin/mount","bin/switch_root"):
        need(name in entries,f"initramfs missing {name}")
        mode,payload=entries[name]
        need(stat.S_ISREG(mode) and mode&0o111,f"{name} not executable regular file")
    need(entries["init"][1].startswith(b"#!/bin/sh"),"invalid init")
    for name,(mode,payload) in entries.items():
        if stat.S_ISREG(mode) and payload.startswith(b"\x7fELF"):
            need(len(payload)>=20 and payload[4:6]==b"\x02\x01" and struct.unpack_from("<H",payload,18)[0]==183,
                 f"non-aarch64 ELF: {name}")
    if components:
        for section,filename in [("kernel","Image.gz"),("ramdisk","initramfs.cpio.gz"),("dtb","begonia.dtb"),("recovery_dtbo","empty.dtbo")]:
            need(sections[section]==(Path(components)/filename).read_bytes(),f"embedded {section} differs")
    return {"structural_validation":"passed","device_boot":"UNTESTED","flash_authorized":False,
            "measured_partition_fit":boot_partition_bytes is not None,"bytes":len(data),"cmdline":cmd,
            "sha256":hashlib.sha256(data).hexdigest(),"component_bytes":dict(zip(sections,sizes)),
            "initramfs_entries":len(entries)}

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("image",type=Path)
    p.add_argument("--components",type=Path)
    p.add_argument("--boot-partition-bytes",type=int)
    a=p.parse_args()
    print(json.dumps(validate(a.image.read_bytes(),a.components,a.boot_partition_bytes),indent=2))
