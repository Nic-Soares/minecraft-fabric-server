# Changelog

Mudanças de cada release. Formato baseado no [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); versões seguem [SemVer](https://semver.org/lang/pt-BR/) com as regras do `GIT.md`, seção **Versões e releases**.

## [Não lançado]

## [0.1.0] - 2026-09-27

Primeira release. Servidor Fabric rodando nativo no macOS, com amigos entrando pelo Tailscale.

### Stack

| Componente | Versão |
|---|---|
| JDK (Temurin) | 25 |
| Minecraft | 26.3 |
| Fabric Loader | 0.19.5 |
| Fabric Installer | 1.1.2 |
| Mods (`mods.lock`) | fabric-api, lithium, ferrite-core, c2me-fabric, scalablelux, spark, chunky |

### Adicionado

- Stack fixada em `versions.env` e mods resolvidos em `mods.lock` com sha512 (`scripts/mods.sh update|sync`)
- `scripts/install.sh`, `start.sh`, `backup.sh`, `rcon.py` e `lib.sh`; o `start.sh` gera o `server.properties` a partir do `.base` e dos segredos do `scripts/.env`
- `scripts/service.sh`, que gera o job do launchd a partir de `launchd/minecraft.plist.template`
- Conexão de jogadores externos via Tailscale, com o modelo de política em `network/tailscale-policy.example.hujson`
- Padrão de mensagem de commit com `.gitmessage` e hooks `pre-commit` e `commit-msg`
- Documentação: `ARCHITETURE.html`, `GIT.md`, `docs/SETUP.md`, `docs/SCRIPTS.md`, `docs/OPERACAO.md` e `docs/MULTIPLAYER.md`

### Corrigido

- Política do Tailscale: amigos de compartilhamento não alcançavam a porta 25565
- Política do Tailscale: aviso de valor inválido no console
- Docs: IP fixo da rede local trocado pelo comando que o descobre

### Segurança

- `server/whitelist.json`, `server/ops.json` e o IP Tailscale do Mac saem do repositório; o `pre-commit` bloqueia os dois JSONs

[Não lançado]: https://github.com/Nic-Soares/minecraft-fabric-server/compare/v0.1.0...development
[0.1.0]: https://github.com/Nic-Soares/minecraft-fabric-server/releases/tag/v0.1.0
