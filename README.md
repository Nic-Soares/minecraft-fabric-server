# minecraft-fabric-server

Servidor dedicado Minecraft Java 26.3 com Fabric, rodando nativo no macOS (Apple Silicon), com mods de desempenho só no servidor e amigos entrando pelo Tailscale, sem abrir portas no roteador.

## Documentação

| Documento | Conteúdo |
|---|---|
| [docs/ARQUITETURA.md](docs/ARQUITETURA.md) | Visão geral, rede, fluxos de boot e backup, arquivos do projeto |
| [docs/STACK.md](docs/STACK.md) | Versões, memória, decisões técnicas e flags da JVM |
| [docs/SETUP.md](docs/SETUP.md) | Instalação do zero, passo a passo |
| [docs/SCRIPTS.md](docs/SCRIPTS.md) | O que cada script faz |
| [docs/OPERACAO.md](docs/OPERACAO.md) | Dia a dia: ligar, desligar, logs, jogadores, backup |
| [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md) | Conexão de amigos pelo Tailscale |
| [docs/GIT.md](docs/GIT.md) | Versionamento, branches, commits e releases |
| [CHANGELOG.md](CHANGELOG.md) | Mudanças de cada release |

## Início rápido

```bash
~/Servers/minecraft/scripts/service.sh start
```

Primeira vez nesta máquina: siga o [docs/SETUP.md](docs/SETUP.md).
