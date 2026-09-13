# Sistemas pro Roblox — Glear 🎮

## Projetos principais

Cinco sistemas mais completos, conectados numa arena de demonstração: economia e loja, campanha de missões, combate com habilidades, ondas de sobrevivência e construção por grade.

[Conheça o kit avançado e instale os cinco juntos](principais/README.md). Inclui salvamento, painel jogável e testes de integração. Ainda precisa de validação no motor Roblox.

## Projetos básicos


Ideias pequenas pra colocar no jogo, testar e ir melhorando. Cada pasta tem um sistema independente, com instalador, código separado e explicação de como usar.

| Projeto | O que faz |
| --- | --- |
| [Checkpoints de obby](checkpoints-obby) | Avance por etapas em ordem e renasça no último checkpoint alcançado. |
| [Coleta de moedas](coleta-de-moedas) | Moedas coletáveis com saldo individual e tempo de reaparecimento por jogador. |
| [Missão de exploração](missao-de-exploracao) | Visite três pontos do mapa e resgate uma recompensa única durante a sessão. |
| [Corrida com energia](corrida-com-energia) | Corrida com gasto de energia, recuperação e controle pelo servidor. |
| [Ciclo de dia e noite](ciclo-dia-noite) | Relógio sincronizado com iluminação gradual e duração configurável. |

## Como começar

Abra a pasta do sistema, copie `Instalar.lua` e rode na **Command Bar do Roblox Studio com o Play parado**. Salve e teste num Baseplate com SpawnLocation. Cada sistema tem sua própria aba lateral, então dá pra instalar os cinco no mesmo lugar.

São bases funcionais de código, com regras testadas localmente. **Ainda precisam ser validadas no Roblox Studio.** Não tem promessa de jogo pronto, segurança absoluta ou persistência: checkpoints, moedas e missão ficam na sessão; energia reinicia no respawn e o relógio no novo servidor.

O sistema de pets continua no [repositório próprio](https://github.com/glearflame/sistema-de-pets-roblox). Estes módulos não conectam suas recompensas aos pets automaticamente.

## Testes locais

Com Node.js instalado:

```text
npm ci
npm test
```

Verificamos sintaxe de todos os arquivos, sequência de checkpoints, recarga e isolamento de moedas, recompensa única, consumo/recuperação de energia e passagem de dias. Os serviços e a interface do Roblox não são executados pelo teste.

Se alterar os arquivos de `src/`, rode `npm run build` para atualizar os instaladores e depois `npm test`.

## Pra conferir no Studio

- Instalar uma vez e verificar se a segunda instalação cancela sem duplicar nada.
- Entrar com dois jogadores e verificar que o progresso não se mistura.
- Testar plataformas, prompts, botões no celular e Shift no computador.
- Morrer e renascer; sair e entrar novamente.
- Verificar o Output e ajustar as posições dos exemplos ao seu mapa.

Referências: [limite entre cliente e servidor](https://create.roblox.com/docs/scripting/security/client-server-boundary), [ProximityPrompt](https://create.roblox.com/docs/ui/proximity-prompts) e [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting).
