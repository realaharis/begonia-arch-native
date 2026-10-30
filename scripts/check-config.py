#!/usr/bin/env python3
import sys
def parse(path):
    result = {}
    for line in open(path):
        if line.startswith("CONFIG_"):
            k, v = line.strip().split("=", 1)
            result[k] = v
        elif line.startswith("# CONFIG_") and line.endswith(" is not set\n"):
            result[line.split()[1]] = "n"
    return result
actual, requested = map(parse, sys.argv[1:3])
bad = {k: (v, actual.get(k, "absent")) for k, v in requested.items()
       if actual.get(k, "n") != v}
if bad:
    raise SystemExit(f"Kconfig dropped/changed required settings: {bad}")
print(f"All {len(requested)} requested Kconfig settings retained.")
