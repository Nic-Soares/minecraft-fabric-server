# Multiplayer

Como outros jogadores, em outras casas, entram no servidor sem abrir nenhuma porta no roteador.

## Como funciona

O Mac e o computador de cada amigo entram numa rede privada criptografada (Tailscale, baseado em WireGuard). O amigo não entra na sua rede de casa: ele enxerga **só o Mac**, e do Mac **só a porta 25565**.

| Camada | O que protege | Onde fica |
|---|---|---|
| Rede privada Tailscale | Só dispositivos autorizados enxergam o Mac. Nada fica exposto na internet. | App Tailscale no Mac e em cada amigo |
| Compartilhamento do Mac | O amigo usa a própria conta e recebe acesso a um único dispositivo, o Mac, e não à sua rede | Console do Tailscale, botão Share |
| Política de acesso | O amigo alcança só `tcp:25565`. RCON (25575) e o resto ficam invisíveis. | `network/tailscale-policy.hujson` (local) |
| Conta Microsoft (`online-mode=true`) | Ninguém entra fingindo ser outra pessoa | `server.properties.base` |
| Whitelist | Só nicks liberados entram, mesmo com acesso à rede | `server/whitelist.json` (local) |

O tráfego vai direto entre os computadores (P2P). Quando um firewall bloqueia a conexão direta, o Tailscale passa por um relay dele (DERP): funciona, com mais latência.

Neste guia, `100.x.y.z` é o **IP Tailscale do Mac**, descoberto no passo 2. O valor real não fica no repositório.

## O que fica fora do Git

| Arquivo local | Modelo versionado | Por quê |
|---|---|---|
| `network/tailscale-policy.hujson` | `network/tailscale-policy.example.hujson` | Tem o IP Tailscale do Mac |
| `server/whitelist.json`, `server/ops.json` | Nenhum; o servidor cria e mantém | Nicks e UUIDs dos jogadores |

## Configurar o Mac (uma vez) · cerca de 10 min

### 1. Instalar o Tailscale

```bash
brew install --cask tailscale-app
```

Antes do login, desconecte qualquer outra VPN (Proton VPN, por exemplo). O macOS mantém um só túnel VPN ativo por vez; com outra VPN ligada, o login do Tailscale trava na tela "Join a tailnet".

Abra o Tailscale pelo Launchpad e clique em **Sign in to your network**. O login é pelo navegador (Google, Microsoft ou GitHub) e cria a conta se ela não existir. A conta que você usar vira a dona da rede.

**Pronto quando:** o ícone do Tailscale na barra de menus mostra **Connected**.

### 2. Descobrir o IP e o nome do Mac na rede Tailscale

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4
/Applications/Tailscale.app/Contents/MacOS/Tailscale status --self --peers=false
```

**Pronto quando:** você tem um IP no formato `100.x.y.z` e o nome da máquina.

### 3. Aplicar a política de acesso

1. Crie a política local a partir do modelo, já com o IP do passo 2:
   ```bash
   cd ~/Servers/minecraft/network && cp tailscale-policy.example.hujson tailscale-policy.hujson && sed -i '' "s/100\.x\.y\.z/$(/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4)/" tailscale-policy.hujson
   ```
2. Copie o arquivo: `pbcopy < ~/Servers/minecraft/network/tailscale-policy.hujson`
3. Abra https://login.tailscale.com/admin/acls e clique na aba **JSON editor**. A página abre no **Visual editor**, que não aceita colar texto.
4. Clique dentro do texto, aperte `Cmd+A` e depois `Cmd+V`. A política colada substitui toda a anterior.
5. Clique em **Save**.

**Pronto quando:** o console salva sem erro e o texto mostra o IP real no lugar de `100.x.y.z`. Se ele recusar, a mensagem diz a linha com problema.

Para mudar a política depois: altere o modelo `.example.hujson`, faça commit e repita este passo.

### 4. Desativar a expiração da chave do Mac

Por padrão, cada dispositivo precisa refazer o login a cada 180 dias. Se isso acontecer com o Mac, todos os amigos perdem o acesso sem aviso.

Em https://login.tailscale.com/admin/machines: menu **…** do Mac, depois **Disable key expiry**.

**Pronto quando:** o Mac aparece na lista sem data de expiração.

## Uma VPN por vez

Enquanto o Mac for o servidor dos amigos, o Tailscale precisa ficar conectado, então outras VPNs (como a Proton VPN) ficam desligadas neste Mac. Elas continuam funcionando nos seus outros aparelhos. O mesmo vale para o computador do amigo.

## Adicionar um amigo · 5 min

| Quem | O que faz |
|---|---|
| Amigo | Instala o Tailscale (https://tailscale.com/download), cria a conta e deixa o app **Connected** |
| Você | Em https://login.tailscale.com/admin/machines, menu **…** do Mac, depois **Share**. Gere o link de convite e mande para o amigo. |
| Amigo | Abre o link e aceita o convite, logado na conta do Tailscale dele |
| Você | Libera o nick dele: `~/Servers/minecraft/scripts/rcon.py "whitelist add NICK_DO_AMIGO"` |
| Amigo | No Minecraft: **Multiplayer**, **Add Server**, e em **Server Address** o IP Tailscale do Mac. Depois **Join Server**. |

O amigo usa o **mesmo** IP Tailscale do Mac, de qualquer lugar. O IP da sua rede de casa (veja com `ipconfig getifaddr en0`) só funciona dentro dela e pode mudar a cada reconexão do Wi-Fi.

**Pronto quando:** o amigo entra no mundo e `~/Servers/minecraft/scripts/rcon.py list` mostra o nick dele. Do seu lado, `/Applications/Tailscale.app/Contents/MacOS/Tailscale status` passa a listar o aparelho dele.

## Remover um amigo

1. `~/Servers/minecraft/scripts/rcon.py "whitelist remove NICK_DO_AMIGO"`
2. Em https://login.tailscale.com/admin/machines, menu **…** do Mac, **Share**, e remova o acesso dele.

## O Mac precisa estar acordado

O servidor só responde com o Mac ligado e acordado. O `start.sh` já impede o sleep por inatividade, mas **fechar a tampa põe o Mac para dormir**, a não ser que ele esteja na tomada com monitor externo.

## Diagnóstico

| Sintoma | Causa provável | Verificação |
|---|---|---|
| Minecraft mostra `Connection timed out: getsockopt` | A conexão não chega ao Mac: Tailscale do amigo desligado, convite não aceito ou política que não libera o tráfego | O amigo roda `tailscale status` e deve ver o nome do Mac |
| `ping` do amigo responde de outro IP com "TTL expirou em trânsito" | O pacote saiu pela internet comum, não pelo Tailscale: o app dele não está conectado ou não conhece o Mac | O amigo abre o Tailscale e confere **Connected** |
| O Mac não lista nenhum aparelho em `Tailscale status`, mesmo com o convite aceito | A política não permite tráfego entre os dois; o Tailscale só distribui aparelhos que podem se falar | Refazer o passo 3; a regra dos amigos usa origem `"*"` (`autogroup:shared` não funciona) |
| `Connection refused: getsockopt` | Chegou no Mac, mas no endereço ou porta errados | O endereço é exatamente o IP Tailscale do Mac, sem porta |
| `tailscale ping` responde "via DERP" | Sem conexão direta; o relay funciona, mas com mais latência | Normal em algumas redes; nada a fazer |
| Login do Tailscale trava em "Join a tailnet", ou o Tailscale desconecta sozinho | Outra VPN ligada no Mac (Proton VPN) | `scutil --nc list`: só o Tailscale pode aparecer como `Connected` |
| "You are not white-listed" | Nick fora da whitelist | `~/Servers/minecraft/scripts/rcon.py "whitelist list"` |
| "Outdated server" ou "Outdated client" | Versão do jogo do amigo diferente de 26.3 | Amigo escolhe a 26.3 em **Installations** |
| Funcionava e parou para todos | Chave do Mac expirou ou o Mac dormiu | Passo 4 e a tampa do Mac |
