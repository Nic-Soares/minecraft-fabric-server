#!/usr/bin/env bash
# Installs Minecraft + Fabric Loader at the versions in versions.env.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
JAVA="$(java_bin)"
cd "$ROOT/server"

JAR="fabric-installer-$INSTALLER_VERSION.jar"
curl -fsSLO "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$INSTALLER_VERSION/$JAR"
trap 'rm -f "$JAR"' EXIT
"$JAVA" -jar "$JAR" server -mcversion "$MC_VERSION" -loader "$LOADER_VERSION" -downloadMinecraft
echo "Installed: Minecraft $MC_VERSION, Fabric Loader $LOADER_VERSION"
