#!/usr/bin/env python3
"""wait-for-lock.py - Block until a file's fcntl (POSIX) lock is free.

Usage: wait-for-lock.py <lock-file>

Returns once no other process holds the lock (immediately if it is free or
the file doesn't exist), printing a message first if it has to wait. The lock
is only probed, never kept: it is released as soon as this script exits. Used
by entrypoint.sh to wait on the AP's $LOCK/InstanceLock, which HTCondor's
master holds via fcntl. Waiting uses a blocking lock request, so there is no
polling.

Exit status: 0 once the lock is free, 2 on any error.
"""
import errno
import fcntl
import sys


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    path = sys.argv[1]
    try:
        with open(path, "r+") as f:
            try:
                fcntl.lockf(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError as e:
                if e.errno not in (errno.EACCES, errno.EAGAIN):
                    raise
                print(f"==> {path} is locked by another AP; waiting for it to be released", flush=True)
                fcntl.lockf(f, fcntl.LOCK_EX)
    except FileNotFoundError:
        pass
    except OSError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
