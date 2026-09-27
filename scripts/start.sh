#!/usr/bin/env bash
# Starts the server. In the foreground when run from a terminal; launchd uses the same script.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env
JAVA="$(java_bin)"
HEAP="${MC_HEAP:-6G}"
cd "$ROOT/server"
mkdir -p logs

# versioned config + local secrets; the server rewrites this file on boot
{ cat server.properties.base
  echo "rcon.password=$RCON_PASS"
  echo "management-server-secret=$MGMT_SECRET"; } > server.properties

# prevent idle sleep while this PID lives (exec keeps the PID)
caffeinate -i -w $$ &

exec "$JAVA" -Xms"$HEAP" -Xmx"$HEAP" \
  -XX:+UseZGC \
  -XX:+UseCompactObjectHeaders \
  -XX:+AlwaysPreTouch \
  -XX:+PerfDisableSharedMem \
  --enable-native-access=ALL-UNNAMED \
  --sun-misc-unsafe-memory-access=allow \
  -Xlog:gc*:file=logs/gc.log:time,uptime:filecount=5,filesize=10M \
  -jar fabric-server-launch.jar nogui
