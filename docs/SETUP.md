# Setup

Step by step to build the server from scratch. All commands run in Terminal, from any folder. The architecture is in [ARCHITECTURE.md](ARCHITECTURE.md); what each script does, in [SCRIPTS.md](SCRIPTS.md).

Total time: about 20 minutes, plus the optional world pre-generation.

## 1. Install JDK 25 and zstd · 2 min

```bash
brew install --cask temurin@25 && brew install zstd
```

**Done when:** `/usr/libexec/java_home -V` lists 25.

## 2. Install Minecraft + Fabric · 3 min

```bash
~/Servers/minecraft/scripts/install.sh
```

**Done when:** `~/Servers/minecraft/server/fabric-server-launch.jar` exists.

## 3. Download the mods · 1 min

```bash
~/Servers/minecraft/scripts/mods.sh sync
```

**Done when:** the script prints 7 `ok` lines.

## 4. Accept the EULA · 1 min

Read the EULA at https://aka.ms/MinecraftEULA. If you agree:

```bash
sed -i '' 's/eula=false/eula=true/' ~/Servers/minecraft/server/eula.txt
```

**Done when:** `tail -1 ~/Servers/minecraft/server/eula.txt` shows `eula=true`.

## 5. Generate the passwords · 1 min

```bash
(umask 077; printf 'RCON_PASS=%s\nMGMT_SECRET=%s\n' "$(openssl rand -hex 24)" "$(openssl rand -hex 24)" > ~/Servers/minecraft/scripts/.env)
```

**Done when:** `ls -l ~/Servers/minecraft/scripts/.env` starts with `-rw-------`.

## 6. Test in the terminal · 2 min

```bash
~/Servers/minecraft/scripts/start.sh
```

**Done when:** `Done (…s)!` appears. Then type `stop` and press Enter.

## 7. Run in the background · 1 min

```bash
~/Servers/minecraft/scripts/service.sh start
```

**Done when:** about 20 s later, `~/Servers/minecraft/scripts/rcon.py list` replies `There are 0 of a max of 20 players online`.

## 8. Allow your nick · 1 min

```bash
~/Servers/minecraft/scripts/rcon.py "whitelist add YOUR_NICK" "op YOUR_NICK"
```

**Done when:** it replies `Added YOUR_NICK to the whitelist` and `Made YOUR_NICK a server operator`.

## 9. Join the game · 1 min

1. In Minecraft, click **Multiplayer** (the first time, click **Proceed** on the warning).
2. Click **Add Server**, type `localhost` in **Server Address** and click **Done**.
3. Select the server and click **Join Server**.

`localhost` means "this same Mac". The game has to be on the same version as the server (26.3). Today it is the Launcher's default version; when 26.4 comes out, update the server or pick 26.3 in **Installations**.

**Done when:** you join the world. Press `T`, type `/spark tps` and check that MSPT is below 25 ms.

## 10. Save to GitHub · 3 min

Create the private, **empty** repo `minecraft-fabric-server` on GitHub (no README). Replace `USERNAME`:

```bash
cd ~/Servers/minecraft && git remote add origin git@github.com:USERNAME/minecraft-fabric-server.git && git push -u origin --all
```

**Done when:** GitHub shows the branches, with no `.jar` and no `.env`. Then, in Settings, set `development` as the default branch and protect `main`.

## 11. Pre-generate the world (optional) · 1 min + 20 to 40 min unattended

Stay connected in the game while it runs. With the server empty for 60 s, it pauses (`pause-when-empty-seconds=60`) and generation stops with it.

```bash
~/Servers/minecraft/scripts/rcon.py "chunky radius 3000" "chunky start"
```

**Done when:** `~/Servers/minecraft/scripts/rcon.py "chunky progress"` shows 100%.

## Clone on another machine

After step 1, instead of steps 2 to 5:

```bash
git clone git@github.com:USERNAME/minecraft-fabric-server.git ~/Servers/minecraft
cd ~/Servers/minecraft
git config core.hooksPath .githooks
git config commit.template .gitmessage
scripts/install.sh && scripts/mods.sh sync
```

Then accept the EULA (step 4), generate the passwords (step 5) and continue from step 6.
