"""Fail when a file contains an em dash. Used as a prek hook."""

import sys

EM_DASH = chr(0x2014)


def main(paths):
    bad = 0
    for path in paths:
        with open(path, encoding="utf-8", errors="ignore") as fh:
            for number, line in enumerate(fh, start=1):
                if EM_DASH in line:
                    print(f"{path}:{number}: em dash found")
                    bad += 1
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
