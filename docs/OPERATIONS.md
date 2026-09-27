# Operations

Day-to-day commands with the server already installed. All of them run in Terminal, from any folder.

## Start, stop, and check if it is running

| I want to | Command |
|---|---|
| Start (background) | `~/Servers/minecraft/scripts/service.sh start` |
| Stop | `~/Servers/minecraft/scripts/service.sh stop` |
| Restart | `~/Servers/minecraft/scripts/service.sh restart` |
| Check if it is running | `~/Servers/minecraft/scripts/service.sh status` |
| See who is online | `~/Servers/minecraft/scripts/rcon.py list` |

`state = running` means running; `state = stopped`, stopped. `stop` only returns after the world has finished saving.

## Logs

### Watch live

```bash
tail -f ~/Servers/minecraft/server/logs/latest.log
```

`Ctrl+C` closes the view. The server keeps running.

### Where each log lives

All of them are in `~/Servers/minecraft/server/logs/`.

| File | What it has | When to look |
|---|---|---|
| `latest.log` | Everything from the current session: player joins and leaves, chat, commands, warnings, errors | Almost always this one |
| `YYYY-MM-DD-N.log.gz` | Previous sessions, compressed. One new file per boot | Investigating something from yesterday |
| `launchd.err` | Errors before the game starts, for example missing `.env` or JDK not found | The server does not start through launchd |
| `launchd.out` | Copy of the console output when running through launchd | Rarely; `latest.log` has the same content |
| `gc.log` | JVM garbage collections (rotates across 5 files of 10 MB) | Periodic freezes; `/spark gc` summarizes it better |

Crashes generate a separate report in `~/Servers/minecraft/server/crash-reports/`.

### Useful filters

| I want to see | Command |
|---|---|
| Who joined and left | `grep -E 'joined the game\|left the game' ~/Servers/minecraft/server/logs/latest.log` |
| Warnings and errors | `grep -E '/(WARN\|ERROR)\]' ~/Servers/minecraft/server/logs/latest.log` |
| Chat | `grep -E '<[A-Za-z0-9_]+> ' ~/Servers/minecraft/server/logs/latest.log` |
| An old log | `gzcat ~/Servers/minecraft/server/logs/2026-09-27-1.log.gz \| less` |
| Why it did not start | `cat ~/Servers/minecraft/server/logs/launchd.err` |

### Warnings that are normal

| Log line | Meaning |
|---|---|
| `Cannot find native library osx-aarch_64-libc2me-opts-natives-math.dylib` | C2ME has no such acceleration for ARM Macs and disables only that module |
| `Unable to parse version 27.0 to a codename` | A library does not know the macOS 27 name yet. No effect |
| `Server empty for 60 seconds, pausing` | Nobody online; the server pauses to save CPU |
| `Thread RCON Client /127.0.0.1 started` | A command from `rcon.py` arrived |

## Players

| I want to | Command |
|---|---|
| Allow a nick | `~/Servers/minecraft/scripts/rcon.py "whitelist add NICK"` |
| Remove a nick | `~/Servers/minecraft/scripts/rcon.py "whitelist remove NICK"` |
| See the whitelist | `~/Servers/minecraft/scripts/rcon.py "whitelist list"` |
| Grant operator | `~/Servers/minecraft/scripts/rcon.py "op NICK"` |
| Kick | `~/Servers/minecraft/scripts/rcon.py "kick NICK reason"` |

The whitelist lives in `server/whitelist.json` and the operators in `server/ops.json`. Both are kept out of Git because they store player nicks and UUIDs; the server maintains these files on its own, so there is nothing to commit when allowing or removing someone. To invite someone from another house, see `docs/MULTIPLAYER.md`.

## Performance

Run in the game chat, as an operator:

| Command | Shows |
|---|---|
| `/spark tps` | TPS and MSPT. MSPT below 50 ms is the limit; below 25 ms there is headroom |
| `/spark health` | CPU, memory, disk, and TPS in a single summary |
| `/spark gc` | Garbage collector pauses |
| `/spark profiler start` and then `/spark profiler stop` | A link with the CPU profile, to find what is weighing things down |

## Backup and restore

```bash
~/Servers/minecraft/scripts/backup.sh
```

Runs with the server running and writes to `~/Servers/minecraft/backups/`. To restore, with the server **stopped**:

```bash
mv ~/Servers/minecraft/server/world ~/Servers/minecraft/server/world.old
zstd -dc ~/Servers/minecraft/backups/FILE.tar.zst | tar -xf - -C ~/Servers/minecraft/server
```

After starting it and checking the world, delete `world.old`.

## Update mods

1. `~/Servers/minecraft/scripts/mods.sh update`
2. `git -C ~/Servers/minecraft diff mods.lock` to see what changed
3. Stop the server, run `~/Servers/minecraft/scripts/mods.sh sync`, and start it again
4. If everything works, commit `mods.lock` on a branch
