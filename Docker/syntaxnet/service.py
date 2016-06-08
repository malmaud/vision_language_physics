#!/usr/bin/env python

import SocketServer
import struct
from subprocess import Popen, PIPE, STDOUT

class Handler(SocketServer.StreamRequestHandler):
    def handle(self):
        size_str = self.rfile.read(8)
        size = struct.unpack("<Q", size_str)[0]
        data = self.rfile.read(size)
        p = Popen(['syntaxnet/demo.sh'], stdin=PIPE, stdout=PIPE)
        o = p.communicate(data)
        out = o[0]
        self.wfile.write(struct.pack("<Q", len(out)))
        self.wfile.write(out)

if __name__=="__main__":
    server = SocketServer.TCPServer(("", 1000), Handler)
    server.serve_forever()
