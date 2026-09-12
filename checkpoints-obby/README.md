# Checkpoints de obby

Avance por etapas em ordem e renasça no último checkpoint alcançado.

## Pra usar

1. Abra uma cópia do seu jogo no Roblox Studio e pare o Play.
2. Copie **todo** o arquivo [Instalar.lua](Instalar.lua).
3. Cole na **Command Bar** e execute uma vez. Não coloque o instalador em ServerScriptService.
4. Salve, dê Play e use a aba **Obby** na lateral esquerda.

O instalador cria `GlearCheckpoints` em ServerScriptService, ReplicatedStorage e StarterPlayerScripts, além de `GlearCheckpointsDemo` no Workspace. Cancela se já houver instalação com esses nomes. Use um Baseplate com SpawnLocation para experimentar.

## Como funciona e limites

As quatro plataformas de exemplo ficam em Z=25. Não são um obby completo: você pode mover as plataformas e construir os obstáculos. O progresso dura só a sessão. Checkpoints precisam ser alcançados em ordem. Não use outro script de respawn concorrente sem integração.

Os módulos em `src/` separam as regras, o servidor e a interface. Para personalizar o que já está instalado, edite os scripts no Studio. Para alterar esta distribuição, edite `src/` e rode `npm run build` na raiz para atualizar o instalador.

## Validação

Sintaxe verificada e regras do módulo Core testadas localmente com Lua simulado. Os testes estão na raiz do repositório. **Não foi executado no motor Roblox**: confira os prompts/toques, a interface, dois jogadores e o respawn no Studio antes de usar em produção. Validação de distância e limite de solicitações não substituem um sistema completo contra exploração de movimento.

Nenhum script depende de serviços externos, chaves de API ou assets pagos.
