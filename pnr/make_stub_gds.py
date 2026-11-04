#!/usr/bin/env python3
# make_stub_gds.py - write a GDS containing an EMPTY cell (black-box stub)
# usage: python3 make_stub_gds.py MEM1_1024X32 mem_stub.gds
import struct, sys, time

def rec(rtype, dtype, data=b''):
    return struct.pack('>HBB', 4 + len(data), rtype, dtype) + data

def i2(*v):  return struct.pack('>%dh' % len(v), *v)

def s(txt):
    b = txt.encode()
    return b + (b'\0' if len(b) % 2 else b'')

def r8(x):                       # GDSII 8-byte excess-64 real
    if x == 0: return b'\0' * 8
    e = 64
    while x >= 1:      x /= 16.0; e += 1
    while x < 1/16.0:  x *= 16.0; e -= 1
    m = int(round(x * 2**56))
    if m >= 2**56: m //= 16; e += 1
    return bytes([e]) + m.to_bytes(7, 'big')

cell, out = sys.argv[1], sys.argv[2]
t = time.localtime()
ts = i2(t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec) * 2
g  = rec(0x00, 2, i2(600))                    # HEADER
g += rec(0x01, 2, ts)                         # BGNLIB
g += rec(0x02, 6, s('STUBLIB'))               # LIBNAME
g += rec(0x03, 5, r8(0.0005) + r8(5e-10))     # UNITS (2000 dbu/um)
g += rec(0x05, 2, ts)                         # BGNSTR
g += rec(0x06, 6, s(cell))                    # STRNAME
g += rec(0x07, 0)                             # ENDSTR
g += rec(0x04, 0)                             # ENDLIB
open(out, 'wb').write(g)
print("wrote %s with empty cell %s (%d bytes)" % (out, cell, len(g)))
