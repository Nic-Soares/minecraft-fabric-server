# Setup

Passo a passo para montar o servidor do zero. Todos os comandos rodam no Terminal, de qualquer pasta. A arquitetura está no `ARCHITETURE.html`; o que cada script faz, no `docs/SCRIPTS.md`.

Tempo total: cerca de 20 minutos, mais a pré-geração opcional do mundo.

## 1. Instalar JDK 25 e zstd · 2 min

```bash
brew install --cask temurin@25 && brew install zstd
```

**Pronto quando:** `/usr/libexec/java_home -V` lista o 25.

## 2. Instalar Minecraft + Fabric · 3 min

```bash
~/Servers/minecraft/scripts/install.sh
```

**Pronto quando:** existe `~/Servers/minecraft/server/fabric-server-launch.jar`.

## 3. Baixar os mods · 1 min

```bash
~/Servers/minecraft/scripts/mods.sh sync
```

**Pronto quando:** o script imprime 7 linhas `ok`.

## 4. Aceitar a EULA · 1 min

Leia a EULA em https://aka.ms/MinecraftEULA. Se concordar:

```bash
sed -i '' 's/eula=false/eula=true/' ~/Servers/minecraft/server/eula.txt
```

**Pronto quando:** `tail -1 ~/Servers/minecraft/server/eula.txt` mostra `eula=true`.

## 5. Gerar as senhas · 1 min

```bash
(umask 077; printf 'RCON_PASS=%s\nMGMT_SECRET=%s\n' "$(openssl rand -hex 24)" "$(openssl rand -hex 24)" > ~/Servers/minecraft/scripts/.env)
```

**Pronto quando:** `ls -l ~/Servers/minecraft/scripts/.env` começa com `-rw-------`.

## 6. Testar no terminal · 2 min

```bash
~/Servers/minecraft/scripts/start.sh
```

**Pronto quando:** aparece `Done (…s)!`. Depois digite `stop` e aperte Enter.

## 7. Ligar em segundo plano · 1 min

```bash
launchctl bootstrap gui/$(id -u) ~/Servers/minecraft/local.minecraft-fabric-server.plist
```

**Pronto quando:** uns 20 s depois, `~/Servers/minecraft/scripts/rcon.py list` responde `There are 0 of a max of 20 players online`.

## 8. Liberar o seu nick · 1 min

```bash
~/Servers/minecraft/scripts/rcon.py "whitelist add SEU_NICK" "op SEU_NICK"
```

**Pronto quando:** responde `Added SEU_NICK to the whitelist` e `Made SEU_NICK a server operator`.

## 9. Entrar no jogo · 1 min

1. No Minecraft, clique em **Multiplayer** (na primeira vez, clique em **Proceed** no aviso).
2. Clique em **Add Server**, digite `localhost` em **Server Address** e clique em **Done**.
3. Selecione o servidor e clique em **Join Server**.

`localhost` quer dizer "este mesmo Mac". O jogo precisa estar na mesma versão do servidor (26.3). Hoje é a versão padrão do Launcher; quando sair o 26.4, atualize o servidor ou escolha a 26.3 em **Installations**.

**Pronto quando:** você entra no mundo. Aperte `T`, digite `/spark tps` e confira que o MSPT está abaixo de 25 ms.

## 10. Salvar no GitHub · 3 min

Crie o repo privado e **vazio** `minecraft-fabric-server` no GitHub (sem README). Troque `USUARIO`:

```bash
cd ~/Servers/minecraft && git remote add origin git@github.com:USUARIO/minecraft-fabric-server.git && git push -u origin --all
```

**Pronto quando:** o GitHub mostra as branches, sem nenhum `.jar` e sem `.env`. Depois, em Settings, deixe `development` como branch padrão e proteja a `main`.

## 11. Pré-gerar o mundo (opcional) · 1 min + 20 a 40 min sozinho

Fique conectado no jogo enquanto roda. Com o servidor vazio por 60 s, ele pausa (`pause-when-empty-seconds=60`) e a geração para junto.

```bash
~/Servers/minecraft/scripts/rcon.py "chunky radius 3000" "chunky start"
```

**Pronto quando:** `~/Servers/minecraft/scripts/rcon.py "chunky progress"` mostra 100%.

## Clonar em outra máquina

Depois do passo 1, no lugar dos passos 2 a 5:

```bash
git clone git@github.com:USUARIO/minecraft-fabric-server.git ~/Servers/minecraft
cd ~/Servers/minecraft
git config core.hooksPath .githooks
git config commit.template .gitmessage
scripts/install.sh && scripts/mods.sh sync
```

Depois aceite a EULA (passo 4), gere as senhas (passo 5) e siga do passo 6.
