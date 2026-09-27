# Changelog

Changes in each release. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [SemVer](https://semver.org/) with the rules in [docs/GIT.md](docs/GIT.md#versions-and-releases).

## [Unreleased]

## [0.1.0] - 2026-09-27

First release. Fabric server running natively on macOS, with friends joining through Tailscale.

### Stack

| Component | Version |
|---|---|
| JDK (Temurin) | 25 |
| Minecraft | 26.3 |
| Fabric Loader | 0.19.5 |
| Fabric Installer | 1.1.2 |
| Mods (`mods.lock`) | fabric-api, lithium, ferrite-core, c2me-fabric, scalablelux, spark, chunky |

### Added

- Stack pinned in `versions.env` and mods resolved in `mods.lock` with sha512 (`scripts/mods.sh update|sync`)
- `scripts/install.sh`, `start.sh`, `backup.sh`, `rcon.py` and `lib.sh`; `start.sh` generates `server.properties` from `.base` and the secrets in `scripts/.env`
- `scripts/service.sh`, which generates the launchd job from `launchd/minecraft.plist.template`
- External player connections through Tailscale, with the policy template in `network/tailscale-policy.example.hujson`
- Commit message convention with `.gitmessage` and `pre-commit` and `commit-msg` hooks
- Documentation in English in `docs/`: architecture and stack with Mermaid diagrams, setup, scripts, operations, multiplayer and Git

### Fixed

- Tailscale policy: sharing friends could not reach port 25565
- Tailscale policy: invalid value warning in the console
- Docs: hardcoded local network IP replaced with the command that finds it

### Security

- `server/whitelist.json`, `server/ops.json` and the Mac's Tailscale IP removed from the repository; `pre-commit` blocks both JSONs

[Unreleased]: https://github.com/Nic-Soares/minecraft-fabric-server/compare/v0.1.0...development
[0.1.0]: https://github.com/Nic-Soares/minecraft-fabric-server/releases/tag/v0.1.0
