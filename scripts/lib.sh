# Funções comuns. Uso: source "$(dirname "$0")/lib.sh"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/versions.env"

# O java_home cai para outro JDK em silêncio se a versão pedida não existir; aqui isso vira erro.
java_bin() {
  local home bin
  home="$(/usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null)" || true
  bin="$home/bin/java"
  if [[ -z "$home" ]] || ! "$bin" -version 2>&1 | grep -Eq "version \"${JAVA_VERSION}([.\"])"; then
    echo "JDK $JAVA_VERSION não encontrado. Rode: brew install --cask temurin@$JAVA_VERSION" >&2
    return 1
  fi
  echo "$bin"
}

load_env() {
  if [[ ! -f "$ROOT/scripts/.env" ]]; then
    echo "scripts/.env não existe. Veja o passo 'Gerar as senhas' em docs/SETUP.md" >&2
    exit 1
  fi
  set -a; source "$ROOT/scripts/.env"; set +a
}
