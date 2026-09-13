# Economia e loja

Uma economia que conversa com o resto do jogo: compre poções, melhore o dano e reduza o dano recebido com armadura. As recompensas do combate e das missões entram no mesmo saldo usado na construção.

## Recursos

- Catálogo com preço e limite por item no servidor.
- Débito e entrega sem operações que aguardam resposta no meio da compra.
- Poção consumível com cura, limite de estoque e intervalo entre usos.
- Lâmina e armadura únicas, aplicadas automaticamente.
- Recibos das 64 recompensas mais recentes contra repetição imediata.
- Saldo e inventário incluídos no perfil salvo do kit.

`Core.Buy` retorna sucesso/mensagem. `Core.Reward` recebe um identificador de recompensa gerado pelo servidor. O recibo não substitui um processador de pagamentos e não deve ser usado para produtos em Robux.

[Instale o kit integrado e veja os testes e limites](../README.md). Este módulo é um dos cinco projetos principais; usa a interface e o salvamento compartilhados.
