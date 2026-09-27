#!/usr/bin/env bash
# Starts and stops the server in the background via launchd.
# Usage: scripts/service.sh start | stop | restart | status
set -euo pipefail
source "$(dirname "$0")/lib.sh"
LABEL="local.minecraft-fabric-server"
TEMPLATE="$ROOT/launchd/minecraft.plist.template"
PLIST="$ROOT/launchd/minecraft.plist"
DOMAIN="gui/$(id -u)"

loaded() { launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; }

render() {
  sed -e "s|__ROOT__|$ROOT|g" -e "s|__LABEL__|$LABEL|g" "$TEMPLATE" > "$PLIST"
  plutil -lint -s "$PLIST"
}

start() {
  if loaded; then echo "The server is already running."; return; fi
  render
  launchctl bootstrap "$DOMAIN" "$PLIST"
  echo "Server started. Log: tail -f $ROOT/server/logs/latest.log"
}

stop() {
  if ! loaded; then echo "The server is already stopped."; return; fi
  launchctl bootout "$DOMAIN/$LABEL"
  # wait for the world to finish saving (launchd allows up to 90 s, ExitTimeOut)
  for _ in $(seq 1 90); do loaded || break; sleep 1; done
  echo "Server stopped."
}

status() {
  if loaded; then
    launchctl print "$DOMAIN/$LABEL" | grep -E '^[[:space:]]*(state|pid) =' | head -2 | sed 's/^[[:space:]]*//'
  else
    echo "state = stopped"
  fi
}

case "${1:-}" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  *) echo "Usage: $0 start | stop | restart | status" >&2; exit 2 ;;
esac
