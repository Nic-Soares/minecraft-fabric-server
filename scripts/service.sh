#!/usr/bin/env bash
# Liga e desliga o servidor em segundo plano pelo launchd.
# Uso: scripts/service.sh start | stop | restart | status
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
  if loaded; then echo "O servidor já está ligado."; return; fi
  render
  launchctl bootstrap "$DOMAIN" "$PLIST"
  echo "Servidor ligado. Log: tail -f $ROOT/server/logs/latest.log"
}

stop() {
  if ! loaded; then echo "O servidor já está desligado."; return; fi
  launchctl bootout "$DOMAIN/$LABEL"
  # espera o mundo terminar de salvar (o launchd dá até 90 s, ExitTimeOut)
  for _ in $(seq 1 90); do loaded || break; sleep 1; done
  echo "Servidor desligado."
}

status() {
  if loaded; then
    launchctl print "$DOMAIN/$LABEL" | grep -E '^[[:space:]]*(state|pid) =' | head -2 | sed 's/^[[:space:]]*//'
  else
    echo "state = desligado"
  fi
}

case "${1:-}" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  *) echo "Uso: $0 start | stop | restart | status" >&2; exit 2 ;;
esac
