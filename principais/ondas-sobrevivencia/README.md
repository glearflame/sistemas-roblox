# Ondas de sobrevivência

Uma partida de dez ondas com inimigos cada vez mais resistentes, rápidos e fortes. O jogador administra energia, poções e melhorias para chegar à vitória.

## Recursos

- Estados de espera, intervalo, combate, derrota e vitória.
- Quantidade crescente, limitada a 18 inimigos simultâneos por arena.
- Inimigos controlados pelo servidor, com perseguição e desvio simples de obstáculos.
- Recompensas por eliminação e por onda, ligadas à economia.
- Missões alimentadas pelas eliminações e conclusões de onda.
- Limpeza de inimigos na derrota, saída e reinício; arenas individuais.

Os inimigos de demonstração são blocos. O desvio usa raycasts, não uma solução completa de navegação; obstáculos complexos podem prendê-los. A partida atual reinicia na onda 1, mas as recompensas e o progresso persistente do jogador ficam no perfil.

[Instale o kit integrado e veja os testes e limites](../README.md).
