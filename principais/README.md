# Glear Advanced — cinco sistemas conectados

Uma base de jogo com economia, campanha, combate, ondas e construção funcionando juntas. Cada sistema tem seu próprio módulo de regras; o servidor integra tudo numa arena individual por jogador.

## Os projetos principais

| Projeto | O que entrega |
| --- | --- |
| [Economia e loja](economia-loja) | Compra validada, consumíveis, melhorias, recibos de recompensa e saldo salvo. |
| [Campanha de missões](campanha-missoes) | Quatro objetivos encadeados, progressão por eventos do servidor e recompensas únicas. |
| [Combate com habilidades](combate-habilidades) | Golpe direcional, pulso em área, defesa, energia, recarga e validação de alcance/linha de visão. |
| [Ondas de sobrevivência](ondas-sobrevivencia) | Dez ondas com dificuldade crescente, perseguição de inimigos, intervalos, derrota e vitória. |
| [Construção por grade](construcao-grade) | Prévia de posicionamento, rotação, ocupação de células, custo, remoção com devolução e peças salvas. |

## Instalar e jogar

1. Abra uma cópia de um Baseplate com SpawnLocation no Roblox Studio e deixe o Play parado.
2. Copie **todo** o [InstalarKit.lua](InstalarKit.lua) e execute na **Command Bar**. Não coloque o instalador em ServerScriptService.
3. Salve e dê Play. Abra **KIT AVANÇADO**, no canto superior direito.
4. Na aba **Ondas**, clique em **Entrar / voltar à minha arena**. Sua arena fica acima e afastada da origem do mapa.
5. Na **Loja**, compre um item para começar a campanha. Vá em **Missões** e resgate a etapa para liberar a próxima.
6. Comece as ondas. Use **F** para golpe, **Q** para pulso, **E** para defesa e **H** para poção. Os mesmos comandos estão nos botões do painel.
7. Na aba **Construir**, escolha uma peça e clique em **Selecionar posição no mapa**. A grade fica atrás da posição de entrada. Aproxime-se dela, aponte e clique/toque para colocar. **R** ou o botão gira a peça; **Remover** troca o modo.

Não é necessário instalar os cinco módulos separados. **O instalador único entrega os cinco juntos.** Os módulos dependem da integração em `runtime/`; copiar apenas um `Core.lua` não cria uma interface ou uma arena.

## Regras da demonstração

- Cada jogador começa com 250 moedas e uma poção. Lâmina e armadura são melhorias permanentes do inventário, aplicadas automaticamente no combate.
- Cada inimigo derrotado dá 8 moedas. Completar uma onda dá `30 + onda × 10` moedas.
- A campanha pede: comprar um item, derrotar 3 inimigos, colocar 2 peças e concluir mais 2 ondas. **Resgate a etapa para liberar a próxima**; ações anteriores não contam retroativamente.
- Ao morrer, sair da arena ou clicar em voltar à arena, a partida termina. O próximo início começa na onda 1; moedas, compras, campanha e construções são preservadas.
- Construção: grade 9×9, sem empilhamento, até 30 peças. Parede custa 20, pilar 15 e piso 10. Remover devolve metade do custo. Não é possível editar a construção de outro jogador.
- Há até 8 arenas por servidor por padrão. `Config.MaxArenas`, `ArenaOrigin` e `ArenaSpacing` podem ser ajustados; mais arenas exigem testes de desempenho.
- Inimigos são blocos ancorados movidos pelo servidor, com perseguição e desvio simples de obstáculos. Não usam pathfinding completo, rig, animações ou assets externos. Geometria complexa pode prendê-los.

## Salvamento

O módulo `Store` usa `UpdateAsync`, cópia do perfil, validação de versão e trava de sessão. Salva a cada 60 segundos, na saída e no encerramento. Operações têm até três tentativas. Falha de carregamento impede a entrada em vez de substituir o progresso por dados vazios.

No Studio, `Config.StudioPersistence=false` por padrão: o teste começa com dados temporários. Para testar salvamento, use uma experiência de teste publicada, habilite o acesso aos serviços de API e altere essa opção para `true`. O Studio usa `GlearAdvanced_Test_v1`, separado de `GlearAdvanced_v1` usado nos servidores publicados.

O perfil salva moedas, itens, etapa/progresso da campanha e peças da construção. Vida, energia, inimigos e partida ativa não são salvos. Uma sessão interrompida pode exigir esperar até 180 segundos pela expiração da trava. Falhas persistentes de serviço podem impedir gravações; confira os avisos `[GlearAdvanced]` no Output.

## Segurança e integração

O cliente pede ações; o servidor calcula preços, dano, alcance, recargas, objetivos e recompensas. Há limite de frequência, checagem de personagem vivo, arena, grade e propriedade. **Isso não é um anticheat completo de movimentação**: a posição do personagem continua sujeita às limitações de network ownership do Roblox. Para um jogo competitivo, adicione validação de movimento e testes de abuso.

Não usa Robux, Developer Products, chaves de API ou pagamentos reais. Esta economia não se conecta automaticamente aos projetos básicos ou ao sistema de pets. O kit também não altera o WalkSpeed do personagem.

## Código e validação

- Cada pasta de projeto contém seu módulo `Core.lua`.
- `shared/Config.lua` define os parâmetros da demonstração.
- `shared/Store.lua` gerencia os dados.
- `runtime/Server.server.lua` integra mundo, módulos, remotes e ciclo de vida.
- `runtime/Client.client.lua` cria painel, comandos e prévia de construção.

Na raiz do repositório, rode `npm ci`, `npm run build:advanced` e `npm test`. Os testes verificam sintaxe, correspondência entre instalador e fontes e 135 verificações de regras/integração com DataStore simulado.

**Ainda não executado no motor Roblox.** Antes de publicar um jogo, teste no Studio com dois jogadores: carregamento, compras, derrota/vitória, missão completa, construção, controles de toque, respawn e saída/entrada com persistência. O portfólio apresenta código e funcionalidades implementadas, não uma certificação de produção ou uma demonstração já validada no Studio.
