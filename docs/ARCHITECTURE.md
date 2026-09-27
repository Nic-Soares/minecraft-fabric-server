# Architecture

How the server is put together: processes, network, boot and backup flows, and where each file lives. Versions, memory, and the reasoning behind each choice are in [STACK.md](STACK.md).

## Overview

```mermaid
flowchart TB
  subgraph clients["Clients · vanilla 26.3, no mods"]
    local["Launcher on the same Mac<br/>localhost:25565"]
    friend["Friend at another house<br/>100.x.y.z:25565 via Tailscale"]
  end

  subgraph control["Control plane · scripts/"]
    service["service.sh<br/>start · stop · restart · status"]
    ops["backup.sh · mods.sh"]
    rcon["rcon.py"]
  end

  subgraph mac["macOS 27 · Apple M5 · 24 GB"]
    launchd["launchd<br/>local.minecraft-fabric-server"]
    start["start.sh<br/>generates server.properties · caffeinate -w"]
    subgraph java["1 Java process · same PID as start.sh"]
      mods["Mods<br/>Lithium · FerriteCore · C2ME · ScalableLux<br/>spark · Chunky · Fabric API"]
      mc["Minecraft Dedicated Server 26.3<br/>20 TPS · 50 ms per tick"]
      loader["Fabric Loader 0.19.5<br/>Knot + Mixin"]
      jvm["JVM Temurin 25<br/>ZGC · Compact Object Headers · 6 GB heap"]
    end
  end

  subgraph storage["Storage · APFS"]
    world[("server/world/")]
    modsdir[("server/mods/ · config/")]
    logs[("server/logs/<br/>latest.log · gc.log")]
    backups[("backups/<br/>world-DATE-HASH.tar.zst")]
  end

  local -- "TCP 25565" --> mc
  friend -- "TCP 25565" --> mc
  service --> launchd --> start -- "exec" --> jvm
  jvm --> loader -- "applies the mixins" --> mods --> mc
  ops --> rcon -- "RCON :25575" --> mc
  modsdir --> loader
  mc <--> world
  mc --> logs
  world -. "tar + zstd" .-> backups
```

- **A single process.** `start.sh` ends with `exec`, so the JVM inherits its PID. `launchd` supervises that PID, and `caffeinate -w` holds off sleep while it exists.
- **Mods on the server only.** Fabric Loader injects the mods into the game bytecode (Mixin). The client joins with vanilla 26.3.
- **Control from outside the game.** The scripts talk to the server over RCON, on port 25575, with the password from `scripts/.env`.

## Network

Details and step by step in [MULTIPLAYER.md](MULTIPLAYER.md).

```mermaid
flowchart LR
  subgraph tailnet["Tailnet · WireGuard"]
    mine["My devices<br/>autogroup:member"]
    friend["Friend<br/>machine shared via Share"]
    derp["DERP relay São Paulo<br/>when P2P fails"]
  end

  subgraph mac["Mac · host minecraft · 100.x.y.z"]
    game["Game :25565"]
    rconp["RCON :25575"]
  end

  wifi["Neighbors on the coliving Wi-Fi"]

  mine -- "full access" --> game
  mine -- "full access" --> rconp
  friend -- "tcp:25565 only" --> game
  friend -. "P2P blocked" .-> derp -.-> game
  wifi -- "*:25565 open" --> game
  wifi -- "*:25575 open" --> rconp

  classDef risk stroke:#b45309,stroke-width:2px,stroke-dasharray:5 3
  class wifi risk
```

| Layer | What it guarantees |
|---|---|
| Tailscale | Nothing is exposed to the internet; no port open on the router |
| Access policy | Friend reaches only `tcp:25565`; RCON is invisible to them |
| `online-mode=true` | Nobody gets in pretending to be another Microsoft account |
| Whitelist | Only approved nicks get in, even with network access |

**Open risk:** Java listens on `*:25565` and `*:25575`, so anyone on the same Wi-Fi reaches both ports through the local IP. The fix is planned for v0.2.0.

## Starting and stopping

```mermaid
sequenceDiagram
  actor you as You
  participant svc as service.sh
  participant ld as launchd
  participant st as start.sh
  participant jvm as JVM + server

  you->>svc: start
  svc->>svc: generates launchd/minecraft.plist from the .template
  svc->>ld: launchctl bootstrap
  ld->>st: RunAtLoad
  st->>st: server.properties = .base + secrets from .env
  st->>st: caffeinate -i -w PID
  st->>jvm: exec java (same PID)

  Note over ld,jvm: crash (exit with error) → launchd restarts it<br/>KeepAlive.SuccessfulExit=false

  you->>svc: stop
  svc->>ld: launchctl bootout
  ld->>jvm: SIGTERM
  jvm->>jvm: saves the world and exits
  svc->>svc: waits up to 90 s (ExitTimeOut)
```

## Backup

```mermaid
sequenceDiagram
  participant bk as backup.sh
  participant rc as rcon.py
  participant mc as Server
  participant fs as backups/

  bk->>rc: save-off, save-all flush
  rc->>mc: stops writes and flushes everything to disk
  bk->>fs: tar of server/world/ compressed with zstd
  Note over bk,fs: name: world-YYYY-MM-DD-HHMM-HASH.tar.zst<br/>HASH = repo commit at that moment
  bk->>rc: save-on (trap EXIT, runs even if tar fails)
  rc->>mc: resumes saving normally
```

The server stays up during the backup. `save-off` ensures the world does not change in the middle of `tar`.

## Project files

Root: `~/Servers/minecraft/`.

- `versions.env`: JDK, game, loader, and installer versions
- `mods.txt`: which mods you want (Modrinth slugs)
- `mods.lock`: exact version and sha512 of each mod
- `README.md`, `CHANGELOG.md`: repository entry point and release history
- `docs/`
  - `ARCHITECTURE.md`: this file
  - `STACK.md`: versions, memory, and technical decisions
  - `SETUP.md`: installation step by step
  - `SCRIPTS.md`: what each script does
  - `OPERATIONS.md`: day to day, logs, and players
  - `MULTIPLAYER.md`: connecting friends through Tailscale
  - `GIT.md`: versioning, branches, commits, and releases
- `.gitmessage`, `.githooks/`: commit convention and secrets barrier
- `launchd/minecraft.plist.template`: job template; the real plist is generated and kept out of Git
- `network/tailscale-policy.example.hujson`: policy template; the real one, with the IP, is kept out of Git
- `scripts/`
  - `install.sh`: installs Minecraft + Fabric
  - `service.sh`: starts and stops through launchd
  - `start.sh`: generates `server.properties` and starts the JVM
  - `mods.sh`: `update` and `sync`
  - `rcon.py`: sends commands to the server
  - `backup.sh`: world snapshot
  - `lib.sh`: shared functions
  - `.env`: passwords, out of Git
- `server/`: runtime, almost all out of Git
  - `server.properties.base`: versioned config, no passwords
  - `config/`: mod configs, versioned
  - `whitelist.json`, `ops.json`: local, out of Git
  - `mods/`, `world/`, `logs/`, `*.jar`: out of Git
- `backups/`: out of Git

## Terms

| Term | Meaning |
|---|---|
| localhost | This same computer. It is the address the game uses when the server is on the same Mac. |
| Port 25565 | The server's entry port for the game. 25575 is the RCON one. |
| RCON | Channel for sending commands to the server without being in the game. It is what `rcon.py` uses. |
| launchd | The macOS service manager. Keeps the server running in the background and restarts it if it goes down. |
| MSPT | Milliseconds per tick. The game runs 20 ticks per second, so the limit is 50 ms. Above that, the game lags. |
| DERP | Tailscale relay. Carries the traffic when the direct connection between two computers is blocked. |
