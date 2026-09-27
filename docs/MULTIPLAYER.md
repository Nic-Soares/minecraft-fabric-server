# Multiplayer

Como outros jogadores, em outras casas, entram no servidor sem abrir nenhuma porta no roteador.

## Como funciona

O Mac e o computador de cada amigo entram numa rede privada criptografada (Tailscale, baseado em WireGuard). O amigo não entra na sua rede de casa: ele enxerga **só o Mac**, e do Mac **só a porta 25565**.

| Camada | O que protege | Onde fica |
|---|---|---|
| Rede privada Tailscale | Só dispositivos autorizados enxergam o Mac. Nada fica exposto na internet. | App Tailscale no Mac e em cada amigo |
| Compartilhamento do Mac | O amigo usa a própria conta e recebe acesso a um único dispositivo, o Mac, e não à sua rede | Console do Tailscale, botão Share |
| Política de acesso | O amigo alcança só `tcp:25565`. RCON (25575) e o resto ficam invisíveis. | `network/tailscale-policy.hujson` |
| Conta Microsoft (`online-mode=true`) | Ninguém entra fingindo ser outra pessoa | `server.properties.base` |
| Whitelist | Só nicks liberados entram, mesmo com acesso à rede | `server/whitelist.json` |

**Endereço deste servidor na rede Tailscale: `100.x.y.z`** (nome `nome-do-mac`).

O tráfego vai direto entre os computadores (P2P). Quando um firewall bloqueia a conexão direta, o Tailscale passa por um relay dele (DERP): funciona, com mais latência.

## Configurar o Mac (uma vez) · cerca de 10 min

### 1. Instalar o Tailscale

```bash
brew install --cask tailscale-app
```

Abra o Tailscale pelo Launchpad e faça login. A conta que você usar vira a dona da rede.

**Pronto quando:** o ícone do Tailscale na barra de menus mostra **Connected**.

### 2. Descobrir o IP e o nome do Mac na rede Tailscale

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4
/Applications/Tailscale.app/Contents/MacOS/Tailscale status --self --peers=false
```

**Pronto quando:** você tem um IP no formato `100.x.y.z` e o nome da máquina.

### 3. Aplicar a política de acesso

1. Confira que o IP em `network/tailscale-policy.hujson` é o do passo 2.
2. Copie o arquivo: `pbcopy < ~/Servers/minecraft/network/tailscale-policy.hujson`
3. Abra https://login.tailscale.com/admin/acls e clique na aba **JSON editor**. A página abre no **Visual editor**, que não aceita colar texto.
4. Clique dentro do texto, aperte `Cmd+A` e depois `Cmd+V`.
5. Clique em **Save**.

**Pronto quando:** o console salva sem erro. Se ele recusar, a mensagem diz a linha com problema.

### 4. Desativar a expiração da chave do Mac

Por padrão, cada dispositivo precisa refazer o login a cada 180 dias. Se isso acontecer com o Mac, todos os amigos perdem o acesso sem aviso.

Em https://login.tailscale.com/admin/machines: menu **…** do Mac, depois **Disable key expiry**.

**Pronto quando:** o Mac aparece na lista sem data de expiração.

## Adicionar um amigo · 5 min

| Quem | O que faz |
|---|---|
| Amigo | Instala o Tailscale (https://tailscale.com/download) e cria a conta dele |
| Você | Em https://login.tailscale.com/admin/machines, menu **…** do Mac, depois **Share**. Gere o link de convite e mande para o amigo. |
| Amigo | Abre o link e aceita o convite |
| Você | Libera o nick dele: `~/Servers/minecraft/scripts/rcon.py "whitelist add NICK_DO_AMIGO"` |
| Amigo | No Minecraft: **Multiplayer**, **Add Server**, e em **Server Address** `100.x.y.z`. Depois **Join Server**. |

O amigo usa o **mesmo** IP `100.x.y.z`, de qualquer lugar. O `IP da rede local` só funciona dentro da sua casa.

**Pronto quando:** o amigo entra no mundo e `~/Servers/minecraft/scripts/rcon.py list` mostra o nick dele.

## Remover um amigo

1. `~/Servers/minecraft/scripts/rcon.py "whitelist remove NICK_DO_AMIGO"`
2. Em https://login.tailscale.com/admin/machines, menu **…** do Mac, **Share**, e remova o acesso dele.

## O Mac precisa estar acordado

O servidor só responde com o Mac ligado e acordado. O `start.sh` já impede o sleep por inatividade, mas **fechar a tampa põe o Mac para dormir**, a não ser que ele esteja na tomada com monitor externo.

## Diagnóstico

| Sintoma | Causa provável | Verificação |
|---|---|---|
| "Can't connect to server" | Convite não aceito ou política errada | O amigo roda `tailscale ping 100.x.y.z` |
| `tailscale ping` responde "via DERP" | Sem conexão direta; o relay funciona, mas com mais latência | Normal em algumas redes; nada a fazer |
| "You are not white-listed" | Nick fora da whitelist | `rcon.py "whitelist list"` |
| "Outdated server" ou "Outdated client" | Versão do jogo do amigo diferente de 26.3 | Amigo escolhe a 26.3 em **Installations** |
| Funcionava e parou para todos | Chave do Mac expirou ou o Mac dormiu | Passo 4 e a tampa do Mac |
