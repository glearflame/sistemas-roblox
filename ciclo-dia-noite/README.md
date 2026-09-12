# Ciclo de dia e noite

Relógio sincronizado com iluminação gradual e duração configurável.

## Pra usar

1. Abra uma cópia do seu jogo no Roblox Studio e pare o Play.
2. Copie **todo** o arquivo [Instalar.lua](Instalar.lua).
3. Cole na **Command Bar** e execute uma vez. Não coloque o instalador em ServerScriptService.
4. Salve, dê Play e use a aba **Relógio** na lateral esquerda.

O instalador cria `GlearDayNight` em ServerScriptService, ReplicatedStorage e StarterPlayerScripts, além de `GlearDayNightDemo` no Workspace. Cancela se já houver instalação com esses nomes. Use um Baseplate com SpawnLocation para experimentar.

## Como funciona e limites

Controla ClockTime e Brightness do Lighting. Um dia dura 600 segundos e começa às 08:00; ajuste Core.CycleSeconds e Core.StartHour. Usa tempo decorrido para manter a duração mesmo com variação de quadros. O relógio recomeça quando o servidor inicia. Não use outro controlador de iluminação simultaneamente. Não inclui clima, estações ou skybox.

Os módulos em `src/` separam as regras, o servidor e a interface. Para personalizar o que já está instalado, edite os scripts no Studio. Para alterar esta distribuição, edite `src/` e rode `npm run build` na raiz para atualizar o instalador.

## Validação

Sintaxe verificada e regras do módulo Core testadas localmente com Lua simulado. Os testes estão na raiz do repositório. **Não foi executado no motor Roblox**: confira os prompts/toques, a interface, dois jogadores e o respawn no Studio antes de usar em produção. Validação de distância e limite de solicitações não substituem um sistema completo contra exploração de movimento.

Nenhum script depende de serviços externos, chaves de API ou assets pagos.
