# Operação

Comandos do dia a dia com o servidor já instalado. Todos rodam no Terminal, de qualquer pasta.

## Ligar, desligar e ver se está rodando

| Quero | Comando |
|---|---|
| Ligar (segundo plano) | `~/Servers/minecraft/scripts/service.sh start` |
| Desligar | `~/Servers/minecraft/scripts/service.sh stop` |
| Reiniciar | `~/Servers/minecraft/scripts/service.sh restart` |
| Ver se está rodando | `~/Servers/minecraft/scripts/service.sh status` |
| Ver quem está online | `~/Servers/minecraft/scripts/rcon.py list` |

`state = running` quer dizer ligado; `state = desligado`, desligado. O `stop` só volta depois que o mundo terminou de salvar.

## Logs

### Ver ao vivo

```bash
tail -f ~/Servers/minecraft/server/logs/latest.log
```

`Ctrl+C` fecha a visualização. O servidor continua ligado.

### Onde fica cada log

Todos ficam em `~/Servers/minecraft/server/logs/`.

| Arquivo | O que tem | Quando olhar |
|---|---|---|
| `latest.log` | Tudo da sessão atual: entradas e saídas de jogadores, chat, comandos, avisos, erros | Quase sempre é este |
| `AAAA-MM-DD-N.log.gz` | Sessões anteriores, compactadas. Um arquivo novo por boot | Investigar algo de ontem |
| `launchd.err` | Erros antes do jogo subir, por exemplo `.env` faltando ou JDK não encontrado | O servidor não liga pelo launchd |
| `launchd.out` | Cópia da saída do console quando roda pelo launchd | Raramente; o `latest.log` tem o mesmo conteúdo |
| `gc.log` | Coletas de lixo da JVM (rotaciona em 5 arquivos de 10 MB) | Travadas periódicas; o `/spark gc` resume melhor |

Crashes geram um relatório separado em `~/Servers/minecraft/server/crash-reports/`.

### Filtros úteis

| Quero ver | Comando |
|---|---|
| Quem entrou e saiu | `grep -E 'joined the game\|left the game' ~/Servers/minecraft/server/logs/latest.log` |
| Avisos e erros | `grep -E '/(WARN\|ERROR)\]' ~/Servers/minecraft/server/logs/latest.log` |
| Chat | `grep -E '<[A-Za-z0-9_]+> ' ~/Servers/minecraft/server/logs/latest.log` |
| Um log antigo | `gzcat ~/Servers/minecraft/server/logs/2026-09-27-1.log.gz \| less` |
| Por que não ligou | `cat ~/Servers/minecraft/server/logs/launchd.err` |

### Avisos que são normais

| Linha no log | Significado |
|---|---|
| `Cannot find native library osx-aarch_64-libc2me-opts-natives-math.dylib` | O C2ME não tem essa aceleração para Mac ARM e desliga só esse módulo |
| `Unable to parse version 27.0 to a codename` | Uma biblioteca ainda não conhece o nome do macOS 27. Sem efeito |
| `Server empty for 60 seconds, pausing` | Ninguém online; o servidor pausa para economizar CPU |
| `Thread RCON Client /127.0.0.1 started` | Um comando do `rcon.py` chegou |

## Jogadores

| Quero | Comando |
|---|---|
| Liberar um nick | `~/Servers/minecraft/scripts/rcon.py "whitelist add NICK"` |
| Remover um nick | `~/Servers/minecraft/scripts/rcon.py "whitelist remove NICK"` |
| Ver a whitelist | `~/Servers/minecraft/scripts/rcon.py "whitelist list"` |
| Dar operador | `~/Servers/minecraft/scripts/rcon.py "op NICK"` |
| Expulsar | `~/Servers/minecraft/scripts/rcon.py "kick NICK motivo"` |

A whitelist fica em `server/whitelist.json` e os operadores em `server/ops.json`. Os dois ficam fora do Git, porque guardam nicks e UUIDs dos jogadores; o servidor mantém esses arquivos sozinho, então não há commit a fazer ao liberar ou remover alguém. Para convidar alguém de outra casa, veja `docs/MULTIPLAYER.md`.

## Desempenho

Rode no chat do jogo, como operador:

| Comando | Mostra |
|---|---|
| `/spark tps` | TPS e MSPT. MSPT abaixo de 50 ms é o limite; abaixo de 25 ms há folga |
| `/spark health` | CPU, memória, disco e TPS num resumo só |
| `/spark gc` | Pausas do coletor de lixo |
| `/spark profiler start` e depois `/spark profiler stop` | Um link com o perfil de CPU, para achar o que está pesando |

## Backup e restauração

```bash
~/Servers/minecraft/scripts/backup.sh
```

Roda com o servidor ligado e grava em `~/Servers/minecraft/backups/`. Para restaurar, com o servidor **desligado**:

```bash
mv ~/Servers/minecraft/server/world ~/Servers/minecraft/server/world.antigo
zstd -dc ~/Servers/minecraft/backups/ARQUIVO.tar.zst | tar -xf - -C ~/Servers/minecraft/server
```

Depois de ligar e conferir o mundo, apague `world.antigo`.

## Atualizar mods

1. `~/Servers/minecraft/scripts/mods.sh update`
2. `git -C ~/Servers/minecraft diff mods.lock` para ver o que mudou
3. Desligue o servidor, rode `~/Servers/minecraft/scripts/mods.sh sync` e ligue de novo
4. Se tudo funcionar, faça commit do `mods.lock` numa branch
