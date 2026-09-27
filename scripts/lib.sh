# Shared functions. Usage: source "$(dirname "$0")/lib.sh"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/versions.env"

# java_home silently falls back to another JDK if the requested version is missing; here that becomes an error.
java_bin() {
  local home bin
  home="$(/usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null)" || true
  bin="$home/bin/java"
  if [[ -z "$home" ]] || ! "$bin" -version 2>&1 | grep -Eq "version \"${JAVA_VERSION}([.\"])"; then
    echo "JDK $JAVA_VERSION not found. Run: brew install --cask temurin@$JAVA_VERSION" >&2
    return 1
  fi
  echo "$bin"
}

load_env() {
  if [[ ! -f "$ROOT/scripts/.env" ]]; then
    echo "scripts/.env does not exist. See the 'Generate the passwords' step in docs/SETUP.md" >&2
    exit 1
  fi
  set -a; source "$ROOT/scripts/.env"; set +a
}
