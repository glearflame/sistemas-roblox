# Missão de exploração

Visite três pontos do mapa e resgate uma recompensa única durante a sessão.

## Pra usar

1. Abra uma cópia do seu jogo no Roblox Studio e pare o Play.
2. Copie **todo** o arquivo [Instalar.lua](Instalar.lua).
3. Cole na **Command Bar** e execute uma vez. Não coloque o instalador em ServerScriptService.
4. Salve, dê Play e use a aba **Missão** na lateral esquerda.

O instalador cria `GlearQuest` em ServerScriptService, ReplicatedStorage e StarterPlayerScripts, além de `GlearQuestDemo` no Workspace. Cancela se já houver instalação com esses nomes. Use um Baseplate com SpawnLocation para experimentar.

## Como funciona e limites

A missão começa ao entrar. Os pontos ficam em Z=-40 e usam E ou toque. Depois de visitar os três, abra a aba Missão e resgate 100 créditos. Créditos são uma recompensa demonstrativa própria deste sistema. Não integram automaticamente moedas ou pets. A recompensa é única por sessão; sair e entrar reinicia a missão.

Os módulos em `src/` separam as regras, o servidor e a interface. Para personalizar o que já está instalado, edite os scripts no Studio. Para alterar esta distribuição, edite `src/` e rode `npm run build` na raiz para atualizar o instalador.

## Validação

Sintaxe verificada e regras do módulo Core testadas localmente com Lua simulado. Os testes estão na raiz do repositório. **Não foi executado no motor Roblox**: confira os prompts/toques, a interface, dois jogadores e o respawn no Studio antes de usar em produção. Validação de distância e limite de solicitações não substituem um sistema completo contra exploração de movimento.

Nenhum script depende de serviços externos, chaves de API ou assets pagos.
