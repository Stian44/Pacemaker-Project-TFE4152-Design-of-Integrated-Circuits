import re
import struct
import numpy as np
 
 
def _int(buf, pos):
    return struct.unpack_from("<i", buf, pos)[0]
 
 
def _string(buf, pos):
    n = _int(buf, pos)
    return buf[pos + 4:pos + 4 + n].decode("latin1"), pos + 4 + n
 
 
def read_runs(path):
    """Read every simulation stored in an AIM-Spice .out file."""
    buf = open(path, "rb").read()
    title_re = re.compile(rb"[\x01-\xff]\x00\x00\x00(\d+:[\x20-\x7e]+?)(?=[\x00-\x1f])")
    starts = [m.start() for m in title_re.finditer(buf)
              if _int(buf, m.start()) == len(m.group(1))]
    runs = []
    for k, start in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(buf)
        title, pos = _string(buf, start)
        date, pos = _string(buf, pos)
        analysis, pos = _string(buf, pos)
        # the variable table is preceded by: 4, ?, ?, n_vars, n_points
        for p in range(pos, end - 24):
            if _int(buf, p) != 4:
                continue
            nvar, npts = _int(buf, p + 12), _int(buf, p + 16)
            if not (0 < nvar < 100000 and 0 < npts < 10**7):
                continue
            q = p + 20
            nlen = _int(buf, q)
            if not 0 < nlen < 200:
                continue
            first = buf[q + 4:q + 4 + nlen]
            if not re.fullmatch(rb"[\x20-\x7e]+", first):
                continue
            names = []
            for _ in range(nvar):
                name, q = _string(buf, q)
                q += 4  # variable type (0 = voltage, 1 = current)
                names.append(name)
            data = np.frombuffer(buf, "<f8", nvar * npts, q).reshape(npts, nvar)
            runs.append({"title": title, "date": date, "analysis": analysis,
                         "names": names, "data": data})
            break
    return runs