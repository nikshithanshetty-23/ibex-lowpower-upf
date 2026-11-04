#!/usr/bin/env python3
# add_gds_labels.py - insert TEXT labels into one cell of a GDS (copy, not in place)
# usage: python3 add_gds_labels.py in.gds out.gds TOPCELL NAME:x:y:layer[:texttype] ...
import struct, sys
src, dst, top = sys.argv[1], sys.argv[2], sys.argv[3]
labels = []
for a in sys.argv[4:]:
    p = a.split(':')
    labels.append((p[0], float(p[1]), float(p[2]), int(p[3]), int(p[4]) if len(p) > 4 else 0))

data = open(src, 'rb').read()
def rec(rt, dt, d=b''): return struct.pack('>HBB', 4 + len(d), rt, dt) + d
def s(t):
    b = t.encode(); return b + (b'\0' if len(b) % 2 else b'')

i, out, cur, dbu_per_um, done = 0, bytearray(), None, 2000.0, 0
while i < len(data):
    ln, rt, dt = struct.unpack('>HBB', data[i:i+4])
    if ln == 0: break
    body = data[i+4:i+ln]
    if rt == 0x03:
        m = body[8:16]
        e = (m[0] & 0x7F) - 64; mant = int.from_bytes(m[1:], 'big') / 2**56
        meters_per_dbu = mant * 16**e * (-1 if m[0] & 0x80 else 1)
        dbu_per_um = round(1e-6 / meters_per_dbu)
    if rt == 0x06: cur = body.rstrip(b'\0').decode()
    if rt == 0x07 and cur == top:
        for (n, x, y, ly, tt) in labels:
            out += rec(0x0C, 0) + rec(0x0D, 2, struct.pack('>h', ly)) + rec(0x16, 2, struct.pack('>h', tt))
            out += rec(0x10, 3, struct.pack('>2i', int(round(x*dbu_per_um)), int(round(y*dbu_per_um))))
            out += rec(0x19, 6, s(n)) + rec(0x11, 0)
            done += 1
    out += data[i:i+ln]; i += ln
open(dst, 'wb').write(out)
print("added %d labels to %s (dbu/um=%g) -> %s" % (done, top, dbu_per_um, dst))
if done == 0: sys.exit("ERROR: top cell %s not found" % top)
