# Corrida com energia

Corrida com gasto de energia, recuperação e controle pelo servidor.

## Pra usar

1. Abra uma cópia do seu jogo no Roblox Studio e pare o Play.
2. Copie **todo** o arquivo [Instalar.lua](Instalar.lua).
3. Cole na **Command Bar** e execute uma vez. Não coloque o instalador em ServerScriptService.
4. Salve, dê Play e use a aba **Corrida** na lateral esquerda.

O instalador cria `GlearSprint` em ServerScriptService, ReplicatedStorage e StarterPlayerScripts, além de `GlearSprintDemo` no Workspace. Cancela se já houver instalação com esses nomes. Use um Baseplate com SpawnLocation para experimentar.

## Como funciona e limites

Segure Shift ou abra a aba Corrida e use Correr / Parar. A energia só gasta enquanto existe movimento horizontal observado pelo servidor. O sistema controla WalkSpeed (16/26); integre manualmente se outro script também alterar velocidade. Não inclui animação de corrida nem um detector completo de teleporte/speed hack. A energia reinicia no respawn.

Os módulos em `src/` separam as regras, o servidor e a interface. Para personalizar o que já está instalado, edite os scripts no Studio. Para alterar esta distribuição, edite `src/` e rode `npm run build` na raiz para atualizar o instalador.

## Validação

Sintaxe verificada e regras do módulo Core testadas localmente com Lua simulado. Os testes estão na raiz do repositório. **Não foi executado no motor Roblox**: confira os prompts/toques, a interface, dois jogadores e o respawn no Studio antes de usar em produção. Validação de distância e limite de solicitações não substituem um sistema completo contra exploração de movimento.

Nenhum script depende de serviços externos, chaves de API ou assets pagos.
