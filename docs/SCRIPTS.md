# Scripts

Comandos do dia a dia (ligar, desligar, logs, jogadores): `docs/OPERACAO.md`.

Tudo em `scripts/` é executável e funciona de qualquer pasta. Os `.sh` são scripts de shell (bash); o `.py` é Python 3 e usa só a biblioteca padrão.

## Qual usar

| Quero | Script | Precisa do servidor ligado? |
|---|---|---|
| Instalar ou reinstalar Minecraft + Fabric | `install.sh` | Não (desligue antes) |
| Ligar o servidor no terminal | `start.sh` | Não |
| Baixar os mods do `mods.lock` | `mods.sh sync` | Não (desligue antes) |
| Procurar versões novas dos mods | `mods.sh update` | Não |
| Mandar um comando ao servidor | `rcon.py` | Sim |
| Fazer backup do mundo | `backup.sh` | Sim |

`lib.sh` não é rodado direto; os outros scripts o carregam.

---

## install.sh

**O que faz:** baixa o Fabric Installer e instala o servidor Minecraft com o Fabric Loader dentro de `server/`.

```bash
~/Servers/minecraft/scripts/install.sh
```

- **Lê:** `versions.env` (`MC_VERSION`, `LOADER_VERSION`, `INSTALLER_VERSION`).
- **Cria ou altera:** `server/fabric-server-launch.jar`, `server/server.jar`, `server/libraries/`, `server/versions/`.
- **Não mexe em:** mundo, mods, configs.
- **Quando usar:** na primeira instalação e ao subir de versão do jogo ou do loader.

## start.sh

**O que faz:** monta o `server.properties` e sobe a JVM com as flags de desempenho.

```bash
~/Servers/minecraft/scripts/start.sh
```

Em ordem:

1. Carrega `versions.env` e as senhas de `scripts/.env`.
2. Localiza o JDK 25. Se ele não existir, para com erro (em vez de usar outro Java em silêncio).
3. Gera `server/server.properties` juntando `server.properties.base` com `rcon.password` e `management-server-secret`.
4. Liga o `caffeinate` preso ao processo, para o Mac não dormir enquanto o servidor roda.
5. Substitui a si mesmo pela JVM (`exec`), então o launchd controla o Java diretamente.

- **Heap:** 6 GB por padrão. Para mudar: `MC_HEAP=8G ~/Servers/minecraft/scripts/start.sh`.
- **No terminal:** fica em primeiro plano. Para parar, digite `stop` e aperte Enter, ou use Ctrl+C; os dois salvam o mundo.
- **Pelo launchd:** o `local.minecraft-fabric-server.plist` roda este mesmo script em segundo plano.

## mods.sh

**O que faz:** mantém `server/mods/` igual ao `mods.lock`. Tem dois subcomandos.

### mods.sh update

```bash
~/Servers/minecraft/scripts/mods.sh update
```

- Para cada slug do `mods.txt`, consulta o Modrinth e pega a build Fabric mais recente para `MC_VERSION`.
- Reescreve o `mods.lock` com versão, arquivo, sha512 e URL.
- **Não baixa nada.** Só atualiza o lock para você revisar com `git -C ~/Servers/minecraft diff mods.lock`.
- Falha se algum mod não tiver build para a versão do jogo.

### mods.sh sync

```bash
~/Servers/minecraft/scripts/mods.sh sync
```

- Baixa exatamente o que está no `mods.lock` e verifica o sha512 de cada arquivo.
- Baixa primeiro em `server/.mods.new` e só troca `server/mods/` no fim. Se um download falhar, os mods atuais continuam intactos.
- **Apaga** qualquer arquivo em `server/mods/` que não esteja no lock.

## rcon.py

**O que faz:** manda comandos ao servidor ligado pelo RCON (porta 25575), sem precisar estar no jogo.

```bash
~/Servers/minecraft/scripts/rcon.py "list"
~/Servers/minecraft/scripts/rcon.py "whitelist add NICK" "op NICK"
```

- Cada argumento entre aspas é um comando, executado em ordem.
- Os comandos são os mesmos do console, sem a `/` inicial.
- Lê a senha de `scripts/.env` sozinho.
- **Erros comuns:**
  - `servidor desligado ou RCON desativado`: o servidor não está rodando.
  - `senha recusada`: o `.env` mudou depois do boot. Reinicie o servidor.

## backup.sh

**O que faz:** salva um snapshot consistente do mundo com o servidor ligado.

```bash
~/Servers/minecraft/scripts/backup.sh
```

1. Pelo RCON, desliga a gravação automática (`save-off`) e força salvar tudo em disco (`save-all flush`).
2. Compacta `server/world/` com zstd em `backups/world-AAAA-MM-DD-HHMM-<commit>.tar.zst`.
3. Religa a gravação (`save-on`), mesmo se a compactação falhar.

- O hash do commit no nome mostra com qual versão da stack aquele mundo rodava.
- **Restaurar** (com o servidor desligado): `zstd -dc ARQUIVO.tar.zst | tar -xf - -C ~/Servers/minecraft/server`.

## lib.sh

**O que faz:** reúne as funções comuns dos outros scripts. Não é executado direto.

| Função ou variável | Uso |
|---|---|
| `ROOT` | Caminho absoluto do projeto |
| `versions.env` | Carregado automaticamente |
| `java_bin` | Devolve o caminho do JDK de `JAVA_VERSION`, ou falha com a instrução de instalação |
| `load_env` | Carrega `scripts/.env`, ou falha dizendo como criar |

---

## Arquivos de apoio

| Arquivo | Papel |
|---|---|
| `scripts/.env` | Senhas (`RCON_PASS`, `MGMT_SECRET`). Fora do Git, permissão 600. |
| `scripts/.env.example` | Modelo do `.env`, versionado e sem valores. |
| `local.minecraft-fabric-server.plist` | Job do launchd que roda o `start.sh` em segundo plano. |
