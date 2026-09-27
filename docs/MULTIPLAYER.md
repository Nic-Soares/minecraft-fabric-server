# Multiplayer

How other players, in other homes, join the server without opening any port on the router.

## How it works

The Mac and each friend's computer join an encrypted private network (Tailscale, based on WireGuard). The friend does not join your home network: they see **only the Mac**, and on the Mac **only port 25565**.

| Layer | What it protects | Where it lives |
|---|---|---|
| Tailscale private network | Only authorized devices see the Mac. Nothing is exposed on the internet. | Tailscale app on the Mac and on each friend's computer |
| Mac sharing | The friend uses their own account and gets access to a single device, the Mac, not to your network | Tailscale console, Share button |
| Access policy | The friend reaches only `tcp:25565`. RCON (25575) and everything else stay invisible. | `network/tailscale-policy.hujson` (local) |
| Microsoft account (`online-mode=true`) | Nobody joins pretending to be someone else | `server.properties.base` |
| Whitelist | Only allowed nicks get in, even with network access | `server/whitelist.json` (local) |

Traffic goes directly between the computers (P2P). When a firewall blocks the direct connection, Tailscale goes through one of its relays (DERP): it works, with more latency.

In this guide, `100.x.y.z` is the **Mac's Tailscale IP**, found in step 2. The real value is not in the repository.

## What stays out of Git

| Local file | Versioned template | Why |
|---|---|---|
| `network/tailscale-policy.hujson` | `network/tailscale-policy.example.hujson` | Contains the Mac's Tailscale IP |
| `server/whitelist.json`, `server/ops.json` | None; the server creates and maintains them | Player nicks and UUIDs |

## Set up the Mac (once) · about 10 min

### 1. Install Tailscale

```bash
brew install --cask tailscale-app
```

Before logging in, disconnect any other VPN (Proton VPN, for example). macOS keeps only one VPN tunnel active at a time; with another VPN on, the Tailscale login hangs on the "Join a tailnet" screen.

Open Tailscale from Launchpad and click **Sign in to your network**. Login is through the browser (Google, Microsoft or GitHub) and creates the account if it does not exist. The account you use becomes the network owner.

**Done when:** the Tailscale icon in the menu bar shows **Connected**.

### 2. Find the Mac's IP and name on the Tailscale network

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4
/Applications/Tailscale.app/Contents/MacOS/Tailscale status --self --peers=false
```

**Done when:** you have an IP in the `100.x.y.z` format and the machine name.

### 3. Apply the access policy

1. Create the local policy from the template, already with the IP from step 2:
   ```bash
   cd ~/Servers/minecraft/network && cp tailscale-policy.example.hujson tailscale-policy.hujson && sed -i '' "s/100\.x\.y\.z/$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4)/" tailscale-policy.hujson
   ```
2. Copy the file: `pbcopy < ~/Servers/minecraft/network/tailscale-policy.hujson`
3. Open https://login.tailscale.com/admin/acls and click the **JSON editor** tab. The page opens on the **Visual editor**, which does not accept pasted text.
4. Click inside the text, press `Cmd+A` and then `Cmd+V`. The pasted policy replaces the entire previous one.
5. Click **Save**.

**Done when:** the console saves without errors and the text shows the real IP in place of `100.x.y.z`. If it rejects it, the message says which line has the problem.

To change the policy later: edit the `.example.hujson` template, commit and repeat this step.

### 4. Disable key expiry on the Mac

By default, each device has to log in again every 180 days. If that happens to the Mac, all friends lose access without warning.

At https://login.tailscale.com/admin/machines: the Mac's **…** menu, then **Disable key expiry**.

**Done when:** the Mac appears in the list with no expiry date.

## One VPN at a time

While the Mac is the friends' server, Tailscale has to stay connected, so other VPNs (like Proton VPN) stay off on this Mac. They keep working on your other devices. The same applies to the friend's computer.

## Add a friend · 5 min

| Who | What they do |
|---|---|
| Friend | Installs Tailscale (https://tailscale.com/download), creates the account and leaves the app **Connected** |
| You | At https://login.tailscale.com/admin/machines, the Mac's **…** menu, then **Share**. Generate the invite link and send it to the friend. |
| Friend | Opens the link and accepts the invite, logged into their Tailscale account |
| You | Allow their nick: `~/Servers/minecraft/scripts/rcon.py "whitelist add FRIEND_NICK"` |
| Friend | In Minecraft: **Multiplayer**, **Add Server**, and in **Server Address** the Mac's Tailscale IP. Then **Join Server**. |

The friend uses the **same** Mac Tailscale IP, from anywhere. Your home network IP (check it with `ipconfig getifaddr en0`) only works inside it and can change on every Wi-Fi reconnection.

**Done when:** the friend joins the world and `~/Servers/minecraft/scripts/rcon.py list` shows their nick. On your side, `/Applications/Tailscale.app/Contents/MacOS/Tailscale status` starts listing their device.

## Remove a friend

1. `~/Servers/minecraft/scripts/rcon.py "whitelist remove FRIEND_NICK"`
2. At https://login.tailscale.com/admin/machines, the Mac's **…** menu, **Share**, and remove their access.

## The Mac has to be awake

The server only responds with the Mac on and awake. `start.sh` already prevents idle sleep, but **closing the lid puts the Mac to sleep**, unless it is plugged in with an external monitor.

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| Minecraft shows `Connection timed out: getsockopt` | The connection does not reach the Mac: friend's Tailscale off, invite not accepted or a policy that does not allow the traffic | The friend runs `tailscale status` and should see the Mac's name |
| The friend's `ping` gets a reply from another IP with "TTL expired in transit" | The packet went out over the regular internet, not through Tailscale: their app is not connected or does not know the Mac | The friend opens Tailscale and checks **Connected** |
| The Mac lists no devices in `Tailscale status`, even with the invite accepted | The policy does not allow traffic between the two; Tailscale only distributes devices that can talk to each other | Redo step 3; the friends rule uses source `"*"` (`autogroup:shared` does not work) |
| `Connection refused: getsockopt` | It reached the Mac, but at the wrong address or port | The address is exactly the Mac's Tailscale IP, with no port |
| `tailscale ping` replies "via DERP" | No direct connection; the relay works, but with more latency | Normal on some networks; nothing to do |
| Tailscale login hangs on "Join a tailnet", or Tailscale disconnects on its own | Another VPN on the Mac (Proton VPN) | `scutil --nc list`: only Tailscale may show as `Connected` |
| "You are not white-listed" | Nick not on the whitelist | `~/Servers/minecraft/scripts/rcon.py "whitelist list"` |
| "Outdated server" or "Outdated client" | Friend's game version differs from 26.3 | Friend picks 26.3 in **Installations** |
| It worked and stopped for everyone | The Mac's key expired or the Mac went to sleep | Step 4 and the Mac's lid |
