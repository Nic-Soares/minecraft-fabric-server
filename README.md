# minecraft-fabric-server

Dedicated Minecraft Java 26.3 server with Fabric, running natively on macOS (Apple Silicon), with server-side-only performance mods and friends joining through Tailscale, without opening ports on the router.

## Documentation

| Document | Contents |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Overview, network, boot and backup flows, project files |
| [docs/STACK.md](docs/STACK.md) | Versions, memory, technical decisions and JVM flags |
| [docs/SETUP.md](docs/SETUP.md) | Installation from scratch, step by step |
| [docs/SCRIPTS.md](docs/SCRIPTS.md) | What each script does |
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | Day to day: start, stop, logs, players, backup |
| [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md) | Connecting friends through Tailscale |
| [docs/GIT.md](docs/GIT.md) | Versioning, branches, commits and releases |
| [CHANGELOG.md](CHANGELOG.md) | Changes in each release |

## Quick start

```bash
~/Servers/minecraft/scripts/service.sh start
```

First time on this machine: follow [docs/SETUP.md](docs/SETUP.md).
