#!/usr/bin/env python3
"""Cliente RCON mínimo. Uso: scripts/rcon.py "comando 1" "comando 2" ..."""
import os, pathlib, socket, struct, sys

def load_env():
    env = pathlib.Path(__file__).with_name(".env")
    if "RCON_PASS" not in os.environ and env.exists():
        for line in env.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

def send(s, rid, kind, body):
    data = body.encode() + b"\0\0"
    s.sendall(struct.pack("<iii", len(data) + 8, rid, kind) + data)

def recv(s):
    (n,) = struct.unpack("<i", s.recv(4, socket.MSG_WAITALL))
    data = s.recv(n, socket.MSG_WAITALL)
    rid, _ = struct.unpack("<ii", data[:8])
    return rid, data[8:-2].decode()

load_env()
if not sys.argv[1:]:
    sys.exit(__doc__)
try:
    s = socket.create_connection(("127.0.0.1", int(os.environ.get("RCON_PORT", 25575))), timeout=10)
except ConnectionRefusedError:
    sys.exit("rcon: servidor desligado ou RCON desativado")
with s:
    send(s, 1, 3, os.environ["RCON_PASS"])
    if recv(s)[0] == -1:
        sys.exit("rcon: senha recusada")
    for cmd in sys.argv[1:]:
        send(s, 2, 2, cmd)
        print(recv(s)[1])
