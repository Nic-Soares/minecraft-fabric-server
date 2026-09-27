# Versionamento

O Git guarda tudo que **descreve** o servidor. Tudo que pode ser baixado de novo ou que o jogo gera fica fora. O mundo não vai para o Git; ele é salvo pelo `backup.sh` em `backups/`.

## O que é versionado

| Caminho | Conteúdo |
|---|---|
| `versions.env` | Versões fixadas do JDK, do jogo, do loader e do installer |
| `mods.txt` | Intenção: slugs do Modrinth |
| `mods.lock` | Resolvido: versão exata, arquivo, sha512 e url de cada mod |
| `server/server.properties.base` | Config do servidor, sem segredos |
| `server/config/` | Configs geradas pelos mods (Lithium, C2ME, spark...) |
| `network/tailscale-policy.example.hujson` | Modelo da política do Tailscale, sem o IP do Mac |
| `scripts/` | `start.sh`, `mods.sh`, `rcon.py`, `backup.sh`, `.env.example` |
| `launchd/minecraft.plist.template` | Modelo do job do launchd; o `service.sh` gera o plist real |
| `.githooks/` | `pre-commit` (segredos e binários), `commit-msg` (formato) |
| `.gitmessage` | Template da mensagem de commit |
| `ARCHITETURE.html`, `GIT.md`, `CHANGELOG.md`, `docs/` | Documentação e histórico de releases |

## O que fica fora

| Caminho | Motivo |
|---|---|
| `scripts/.env` | Senhas (`RCON_PASS`, `MGMT_SECRET`) |
| `server/server.properties` | Gerado a cada boot pelo `start.sh`; o servidor reescreve o arquivo |
| `server/*.jar`, `server/libraries/`, `server/versions/`, `server/.fabric/` | Recriados pelo Fabric Installer a partir do `versions.env` |
| `server/mods/` | Recriado pelo `mods.sh sync` a partir do `mods.lock` |
| `server/world/`, `server/logs/`, `server/usercache.json` | Estado e runtime |
| `server/whitelist.json`, `server/ops.json` | Nicks e UUIDs dos jogadores |
| `network/tailscale-policy.hujson` | Política real, com o IP Tailscale do Mac |
| `backups/` | Binários grandes (`.tar.zst`) |

O `.gitignore` ignora `server/*` inteiro e abre exceções explícitas. Um arquivo novo que o servidor criar fica fora do Git até alguém decidir que ele é configuração.

## Versões fixadas

```bash
JAVA_VERSION=25
MC_VERSION=26.3
LOADER_VERSION=0.19.5
INSTALLER_VERSION=1.1.2
```

Os scripts leem só este arquivo. Subir de versão do jogo vira um diff pequeno e revisável.

## Mods: intenção e lock

O modelo é o mesmo de `package.json` e `package-lock.json`.

| Comando | O que faz | Rede |
|---|---|---|
| `scripts/mods.sh update` | Resolve a última build de cada slug para `MC_VERSION` e reescreve o `mods.lock` | Modrinth API |
| `scripts/mods.sh sync` | Apaga `server/mods/`, baixa o que está no lock e verifica o sha512 | Só as URLs do lock |

Formato do `mods.lock` (TSV, ordenado por slug):

```
slug	version_id	filename	sha512	url
```

Fluxo de update:

1. `scripts/mods.sh update`
2. `git diff mods.lock` para revisar o que mudou
3. `scripts/mods.sh sync` e teste o servidor
4. Commit: `mods: lithium 0.26.1 -> 0.26.2`

Rollback: `git revert <commit>` + `scripts/mods.sh sync`.

## Segredos

- A config versionada é o `server/server.properties.base`, sem `rcon.password` e sem `management-server-secret`.
- O `start.sh` junta o base com os valores do `scripts/.env` e grava o `server.properties` real antes de iniciar a JVM.
- O `scripts/.env.example` documenta as variáveis; o `.env` real tem permissão 600 e nunca é commitado.
- O hook `.githooks/pre-commit` bloqueia:
  - arquivos `.jar`, `.zst`, `.mca`, `.dat` e `.env`
  - qualquer linha adicionada com valor em `rcon.password`, `management-server-secret`, `RCON_PASS` ou `MGMT_SECRET`

Os hooks ficam ativos pelo `git config core.hooksPath .githooks`. Essa config é local: depois de clonar em outra máquina, rode o comando de novo.

## Fluxo de branches

| Branch | Papel | Deriva de | Entra em |
|---|---|---|---|
| `main` | Produção: o que roda no servidor que você joga | nenhuma | nenhuma |
| `development` | Integração e testes | `main` (uma vez, no início) | `main` |
| `feature/<nome>` | Uma mudança: mod novo, flag da JVM, script | `development` | `development` |
| `fix/<nome>` | Correção | `development` | `development` |

Ciclo de uma mudança:

1. `git switch development && git pull`
2. `git switch -c feature/adicionar-distant-horizons`
3. Mude, teste com `scripts/start.sh` e faça commit
4. Pull request `feature/...` para `development` e merge
5. Teste a `development` rodando de verdade por um tempo
6. Pull request `development` para `main`, merge e tag de release (ver [Versões e releases](#versões-e-releases))

Nunca faça commit direto na `main`. No GitHub, proteja a `main` (Settings, Branches, exigir pull request) e deixe a `development` como branch padrão, para os PRs já abrirem contra ela.

## Mensagem de commit

Formato:

```
<escopo>: resumo em uma linha

Corpo explicando o que muda e por quê, com o contexto do problema.
Linhas de até 72 caracteres, para o git log ficar legível mesmo
indentado. Pode ter vários parágrafos.

Reported-by: Nome <email>
```

| Regra | Por quê |
|---|---|
| Primeira linha com escopo e até 72 caracteres, sem ponto final | É o que aparece no `git log --oneline`, no gitk e no shortlog |
| Escopos: `config`, `mods`, `jvm`, `scripts`, `docs`, `git` | Filtra o histórico por área: `git log --grep '^mods:'` |
| Segunda linha em branco | O Git separa o título do corpo por ela |
| Corpo com linhas de até 72 (o hook tolera 74) | Leitura no terminal |
| Corpo explica o porquê; o diff já mostra o quê | Contexto que o código não guarda |

Automação:

- `git commit` sem `-m` abre o editor com o template `.gitmessage` (ativado por `git config commit.template .gitmessage`).
- O hook `commit-msg` recusa o commit se o formato estiver errado e diz qual regra falhou. Commits `Merge` e `Revert` gerados pelo Git são aceitos como vêm.
- Sem trailers de assinatura (`Signed-off-by`, `Co-Authored-By`): o autor já fica registrado no próprio commit.

## Versões e releases

O projeto segue [SemVer](https://semver.org/lang/pt-BR/): `vMAJOR.MINOR.PATCH`. A versão é do **projeto** (scripts, configs, docs), não do jogo. A versão do jogo continua no `versions.env` e aparece no `CHANGELOG.md` de cada release.

### O que é o contrato público

SemVer precisa de uma "API" para decidir o que quebra. Aqui ela é tudo em que você ou um script externo dependem:

- Comandos e argumentos dos scripts (`service.sh start|stop|restart|status`, `mods.sh update|sync`, `backup.sh`)
- Variáveis do `scripts/.env` e formato do `versions.env` e do `mods.lock`
- Caminhos que guardam estado: `server/world/`, `backups/`, `server/whitelist.json`, `server/ops.json`
- Compatibilidade do mundo: um mundo salvo nesta versão abre na próxima sem conversão

### Qual número subir

| Mudança | Exemplo | Antes da 1.0 | Depois da 1.0 |
|---|---|---|---|
| Quebra o contrato ou é irreversível | Subir o jogo de 26.3 para 26.4 (o mundo é convertido), renomear variável do `.env`, mudar argumento de script | MINOR | MAJOR |
| Capacidade nova, compatível | Mod novo, script novo, porteiro sob demanda | MINOR | MINOR |
| Correção ou update sem efeito no contrato | Update de patch de mod, flag da JVM, correção de doc | PATCH | PATCH |

Na série `0.x` a regra de MAJOR vira MINOR: a série `0.x` avisa que o contrato ainda muda. A `1.0.0` sai quando o contrato estabilizar: servidor numa máquina dedicada e uma API ou painel web que dependa dele.

### Como publicar uma release

1. Na `development`, mova o conteúdo de `[Não lançado]` do `CHANGELOG.md` para uma seção `[X.Y.Z] - AAAA-MM-DD` e faça commit: `docs: prepara a release vX.Y.Z`
2. Pull request `development` para `main` e merge
3. Tag anotada e assinada no merge da `main`:

   ```bash
   git -C ~/Servers/minecraft switch main && git -C ~/Servers/minecraft pull
   git -C ~/Servers/minecraft tag -s vX.Y.Z -m "vX.Y.Z"
   git -C ~/Servers/minecraft push origin vX.Y.Z
   ```

4. No GitHub: aba **Releases**, botão **Draft a new release**, escolha a tag e cole a seção do `CHANGELOG.md`

Tags só na `main`, nunca em commits da `development` ou de branches. Uma tag publicada não é movida nem apagada: se a release saiu com defeito, a correção vira a próxima PATCH.

### Rollback

`git checkout vX.Y.Z` + `scripts/mods.sh sync` volta à stack daquela release. Se a release seguinte subiu a versão do jogo, restaure também um backup do mundo feito antes dela: o Minecraft não abre um mundo convertido numa versão anterior.

### Backups ligados ao commit

O `backup.sh` usa o hash curto no nome do arquivo, por exemplo `world-2026-09-27-1530-a1b2c3d.tar.zst`, para saber com qual stack aquele mundo rodava. `git describe --tags <hash>` diz de qual release ele é.

## Recriar o servidor do zero

```bash
git clone git@github.com:<usuario>/<repo>.git ~/Servers/minecraft
cd ~/Servers/minecraft
git config core.hooksPath .githooks
git config commit.template .gitmessage
cp scripts/.env.example scripts/.env && chmod 600 scripts/.env
scripts/install.sh
scripts/mods.sh sync
```

Depois é só restaurar um `backups/*.tar.zst` em `server/world/`. O `install.sh` lê o `versions.env` e roda o Fabric Installer.
