# Scripts

Day-to-day commands (start, stop, logs, players): `docs/OPERATIONS.md`.

Everything in `scripts/` is executable and works from any folder. The `.sh` files are shell scripts (bash); the `.py` is Python 3 and uses only the standard library.

## Which one to use

| I want to | Script | Needs the server running? |
|---|---|---|
| Install or reinstall Minecraft + Fabric | `install.sh` | No (stop it first) |
| Start, stop, or restart in the background | `service.sh` | No |
| Start the server in the terminal (test) | `start.sh` | No |
| Download the mods from `mods.lock` | `mods.sh sync` | No (stop it first) |
| Look for new mod versions | `mods.sh update` | No |
| Send a command to the server | `rcon.py` | Yes |
| Back up the world | `backup.sh` | Yes |

`lib.sh` is not run directly; the other scripts source it.

---

## install.sh

**What it does:** downloads the Fabric Installer and installs the Minecraft server with Fabric Loader inside `server/`.

```bash
~/Servers/minecraft/scripts/install.sh
```

- **Reads:** `versions.env` (`MC_VERSION`, `LOADER_VERSION`, `INSTALLER_VERSION`).
- **Creates or changes:** `server/fabric-server-launch.jar`, `server/server.jar`, `server/libraries/`, `server/versions/`.
- **Does not touch:** world, mods, configs.
- **When to use:** on the first install and when upgrading the game or loader version.

## start.sh

**What it does:** builds `server.properties` and starts the JVM with the performance flags.

```bash
~/Servers/minecraft/scripts/start.sh
```

In order:

1. Loads `versions.env` and the passwords from `scripts/.env`.
2. Finds JDK 25. If it does not exist, stops with an error (instead of silently using another Java).
3. Generates `server/server.properties` by merging `server.properties.base` with `rcon.password` and `management-server-secret`.
4. Starts `caffeinate` tied to the process, so the Mac does not sleep while the server runs.
5. Replaces itself with the JVM (`exec`), so launchd controls Java directly.

- **Heap:** 6 GB by default. To change it: `MC_HEAP=8G ~/Servers/minecraft/scripts/start.sh`.
- **In the terminal:** stays in the foreground. To stop, type `stop` and press Enter, or use Ctrl+C; both save the world.
- **In the background:** `service.sh` makes launchd run this same script.

## service.sh

**What it does:** starts, stops, and restarts the server in the background through launchd, the macOS service manager.

```bash
~/Servers/minecraft/scripts/service.sh start
~/Servers/minecraft/scripts/service.sh stop
~/Servers/minecraft/scripts/service.sh restart
~/Servers/minecraft/scripts/service.sh status
```

- **`start`:** generates `launchd/minecraft.plist` from `launchd/minecraft.plist.template`, replacing `__ROOT__` with the project path, and registers the `local.minecraft-fabric-server` job. launchd runs `start.sh` and restarts it if it goes down.
- **`stop`:** removes the job from launchd, which sends SIGTERM to Java; the server saves the world and exits. The script only returns after that.
- **`status`:** shows `state = running` and the `pid`, or `state = stopped`.
- **Why a template:** launchd does not expand `~` or variables inside the plist. The versioned template has no path or username; the generated plist, with the real path, is kept out of Git.
- **Does not start on its own at login:** the plist lives in the project, not in `~/Library/LaunchAgents`.

## mods.sh

**What it does:** keeps `server/mods/` matching `mods.lock`. It has two subcommands.

### mods.sh update

```bash
~/Servers/minecraft/scripts/mods.sh update
```

- For each slug in `mods.txt`, queries Modrinth and takes the latest Fabric build for `MC_VERSION`.
- Rewrites `mods.lock` with version, file, sha512, and URL.
- **Downloads nothing.** It only updates the lock for you to review with `git -C ~/Servers/minecraft diff mods.lock`.
- Fails if any mod has no build for the game version.

### mods.sh sync

```bash
~/Servers/minecraft/scripts/mods.sh sync
```

- Downloads exactly what is in `mods.lock` and verifies the sha512 of each file.
- Downloads first into `server/.mods.new` and only swaps `server/mods/` at the end. If a download fails, the current mods stay intact.
- **Deletes** any file in `server/mods/` that is not in the lock.

## rcon.py

**What it does:** sends commands to the running server over RCON (port 25575), without needing to be in the game.

```bash
~/Servers/minecraft/scripts/rcon.py "list"
~/Servers/minecraft/scripts/rcon.py "whitelist add NICK" "op NICK"
```

- Each quoted argument is one command, run in order.
- The commands are the same as in the console, without the leading `/`.
- Reads the password from `scripts/.env` on its own.
- **Common errors:**
  - `server stopped or RCON disabled`: the server is not running.
  - `password rejected`: `.env` changed after boot. Restart the server.

## backup.sh

**What it does:** saves a consistent snapshot of the world with the server running.

```bash
~/Servers/minecraft/scripts/backup.sh
```

1. Over RCON, turns off automatic saving (`save-off`) and forces everything to be saved to disk (`save-all flush`).
2. Compresses `server/world/` with zstd into `backups/world-YYYY-MM-DD-HHMM-<commit>.tar.zst`.
3. Turns saving back on (`save-on`), even if compression fails.

- The commit hash in the name shows which version of the stack that world was running on.
- **Restore** (with the server stopped): `zstd -dc FILE.tar.zst | tar -xf - -C ~/Servers/minecraft/server`.

## lib.sh

**What it does:** gathers the functions shared by the other scripts. It is not run directly.

| Function or variable | Use |
|---|---|
| `ROOT` | Absolute path of the project |
| `versions.env` | Loaded automatically |
| `java_bin` | Returns the path of the `JAVA_VERSION` JDK, or fails with the install instruction |
| `load_env` | Loads `scripts/.env`, or fails saying how to create it |

---

## Supporting files

| File | Role |
|---|---|
| `scripts/.env` | Passwords (`RCON_PASS`, `MGMT_SECRET`). Out of Git, permission 600. |
| `scripts/.env.example` | `.env` template, versioned and without values. |
| `launchd/minecraft.plist.template` | Versioned launchd job template, without personal paths. |
| `launchd/minecraft.plist` | Job generated by `service.sh`. Out of Git. |
