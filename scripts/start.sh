#!/usr/bin/env bash
# Sobe o servidor. Em primeiro plano quando rodado no terminal; o launchd usa o mesmo script.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env
JAVA="$(java_bin)"
HEAP="${MC_HEAP:-6G}"
cd "$ROOT/server"
mkdir -p logs

# config versionada + segredos locais; o servidor reescreve este arquivo no boot
{ cat server.properties.base
  echo "rcon.password=$RCON_PASS"
  echo "management-server-secret=$MGMT_SECRET"; } > server.properties

# segura o sleep ocioso enquanto este PID viver (o exec mantém o PID)
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
