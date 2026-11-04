#!/usr/bin/env python3
# make_stub_gds_pins.py - black-box GDS of a LEF macro: pin shapes + pin labels only
# usage: python3 make_stub_gds_pins.py <macro.lef> <MACRO> <out.gds> [texttype]
import struct, sys, time, re

GDS = {'Metal1':7,'Metal2':9,'Metal3':11,'Metal4':31,'Metal5':33,'Metal6':35,
       'Metal7':38,'Metal8':40,'Metal9':42}
lef, macro, out = sys.argv[1], sys.argv[2], sys.argv[3]
ttype = int(sys.argv[4]) if len(sys.argv) > 4 else 3
DBU = 2000

txt = open(lef).read()
m = re.search(r'\bMACRO\s+%s\b(.*?)\bEND\s+%s\b' % (re.escape(macro), re.escape(macro)), txt, re.S)
if not m: sys.exit("macro %s not found" % macro)
body = m.group(1)
pins = []
for pm in re.finditer(r'\bPIN\s+(\S+)(.*?)\bEND\s+\1(?=\s)', body, re.S):
    name, pb = pm.group(1), pm.group(2)
    shapes, layer = [], None
    for tok in re.finditer(r'\bLAYER\s+(\S+)\s*;|\bRECT\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*;', pb):
        if tok.group(1): layer = tok.group(1)
        elif layer in GDS:
            x1, y1, x2, y2 = map(float, tok.group(2, 3, 4, 5))
            shapes.append((layer, x1, y1, x2, y2))
    pins.append((name, shapes))

def rec(rt, dt, data=b''): return struct.pack('>HBB', 4 + len(data), rt, dt) + data
def i2(*v): return struct.pack('>%dh' % len(v), *v)
def i4(*v): return struct.pack('>%di' % len(v), *v)
def s(t):
    b = t.encode(); return b + (b'\0' if len(b) % 2 else b'')
def r8(x):
    if x == 0: return b'\0' * 8
    e = 64
    while x >= 1: x /= 16.0; e += 1
    while x < 1/16.0: x *= 16.0; e -= 1
    mm = int(round(x * 2**56))
    if mm >= 2**56: mm //= 16; e += 1
    return bytes([e]) + mm.to_bytes(7, 'big')
def d(v): return int(round(v * DBU))

t = time.localtime(); ts = i2(t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec) * 2
g  = rec(0x00, 2, i2(600)) + rec(0x01, 2, ts) + rec(0x02, 6, s('STUBLIB'))
g += rec(0x03, 5, r8(1.0 / DBU) + r8(1e-6 / DBU))
g += rec(0x05, 2, ts) + rec(0x06, 6, s(macro))
nshape = nlab = 0
for name, shapes in pins:
    for (ly, x1, y1, x2, y2) in shapes:
        X1, Y1, X2, Y2 = d(x1), d(y1), d(x2), d(y2)
        g += rec(0x08, 0) + rec(0x0D, 2, i2(GDS[ly])) + rec(0x0E, 2, i2(0))
        g += rec(0x10, 3, i4(X1, Y1, X2, Y1, X2, Y2, X1, Y2, X1, Y1)) + rec(0x11, 0)
        nshape += 1
    if shapes:
        ly, x1, y1, x2, y2 = shapes[0]
        g += rec(0x0C, 0) + rec(0x0D, 2, i2(GDS[ly])) + rec(0x16, 2, i2(ttype))
        g += rec(0x10, 3, i4(d((x1 + x2) / 2), d((y1 + y2) / 2))) + rec(0x19, 6, s(name)) + rec(0x11, 0)
        nlab += 1
g += rec(0x07, 0) + rec(0x04, 0)
open(out, 'wb').write(g)
print("%s: %d pins, %d shapes, %d labels -> %s" % (macro, len(pins), nshape, nlab, out))
