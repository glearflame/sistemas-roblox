# Combate com habilidades

Três ações com funções diferentes: golpe no inimigo mais próximo à frente, pulso em área e defesa temporária. A loja fornece melhorias e consumíveis que afetam esse combate.

## Recursos

- Energia regenerável e custo por habilidade.
- Recarga calculada pelo servidor.
- Alcance, orientação e linha de visão verificados antes do dano.
- Defesa com duração limitada e redução de dano combinada com armadura.
- Cura consumindo poções do inventário.
- Interface e atalhos F, Q, E e H.

É combate PvE: o jogador só atinge inimigos da própria arena. Não inclui PvP, animações, modelos de armas, efeitos sonoros ou compensação de latência. As regras de energia e recarga ficam em `Core.lua`; alvos e raycasts ficam no servidor compartilhado.

[Instale o kit integrado e veja os testes e limites](../README.md).
