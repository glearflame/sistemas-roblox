# Coleta de moedas

Moedas coletáveis com saldo individual e tempo de reaparecimento por jogador.

## Pra usar

1. Abra uma cópia do seu jogo no Roblox Studio e pare o Play.
2. Copie **todo** o arquivo [Instalar.lua](Instalar.lua).
3. Cole na **Command Bar** e execute uma vez. Não coloque o instalador em ServerScriptService.
4. Salve, dê Play e use a aba **Moedas** na lateral esquerda.

O instalador cria `GlearCoins` em ServerScriptService, ReplicatedStorage e StarterPlayerScripts, além de `GlearCoinsDemo` no Workspace. Cancela se já houver instalação com esses nomes. Use um Baseplate com SpawnLocation para experimentar.

## Como funciona e limites

Cinco moedas em Z=-15. Cada uma vale 10 e pode ser coletada novamente após 20 segundos por jogador. O servidor controla saldo e recarga; cada cliente vê seu próprio estado. O saldo não é salvo entre sessões e não é conectado automaticamente à loja ou ao sistema de pets.

Os módulos em `src/` separam as regras, o servidor e a interface. Para personalizar o que já está instalado, edite os scripts no Studio. Para alterar esta distribuição, edite `src/` e rode `npm run build` na raiz para atualizar o instalador.

## Validação

Sintaxe verificada e regras do módulo Core testadas localmente com Lua simulado. Os testes estão na raiz do repositório. **Não foi executado no motor Roblox**: confira os prompts/toques, a interface, dois jogadores e o respawn no Studio antes de usar em produção. Validação de distância e limite de solicitações não substituem um sistema completo contra exploração de movimento.

Nenhum script depende de serviços externos, chaves de API ou assets pagos.
