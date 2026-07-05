# Atelier Rafa Mendonça — Sistema de Gestão

## Estado atual (5 de julho de 2026)

O ficheiro **`atelier-demo.html`** é o sistema completo e funcional, com todos os módulos:

- Dashboard
- Financeiro (Fecho de Caixa, Fluxo de Caixa, Contas a Pagar/Receber, Comissões, Relatórios, Todos os movimentos)
- Marketing (Canais de aquisição, Calendário, Redes sociais, Investimentos externos)
- Vendas (Funis, Estratégias)
- Estoque & Compras (Produtos, Lista de compras, Registar compra, Saída, Afiar alicates)
- Lista de Compras (colaboradoras)
- Gestão (tarefas)
- Agenda (integração com BUK + lista de espera)

**Importante:** este ficheiro funciona sozinho, só abrindo no browser — mas **todos os dados vivem só na memória**. Se recarregares a página, perdes tudo. É uma demonstração completa e testável do sistema todo, não uma versão para uso diário real.

Acesso com PIN de 4 dígitos:
- Rafa Mendonça (admin): `1111`
- Receção (só Fecho de Caixa): `2222`
- Compras (só Lista de Compras): `3333`

## O que falta para uso real

1. **Base de dados a sério** — o ficheiro `supabase/schema.sql` já tem o esquema completo pronto a correr no Supabase (SQL Editor → colar → Run)
2. **Ligar a aplicação ao Supabase** — o `atelier-demo.html` ainda não fala com nenhuma base de dados; isto é o próximo trabalho: substituir a "memória" React por chamadas reais ao Supabase, para os dados ficarem guardados e sincronizados entre dispositivos
3. **Publicar num link fixo** (Netlify, ligado a este repositório) para poder ser acedido de qualquer telemóvel

## Nota sobre a pasta `projeto-antigo/` (se a vires no histórico)

Existe uma primeira tentativa de estrutura React + Vite + Supabase feita numa fase muito anterior do projeto. Está **desatualizada** face a tudo o que foi construído depois no `atelier-demo.html` — não a uses como base; o trabalho de ligação ao Supabase deve partir do ficheiro demo atual.
