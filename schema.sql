-- ============================================================
-- ATELIER RAFA MENDONÇA — ESQUEMA SUPABASE (atualizado)
-- Reflete todas as funcionalidades construídas: Financeiro,
-- Comissões, Marketing, Estoque/Compras, Lista de Compras,
-- Afiar Alicates, Fluxo de Caixa, Vendas, etc.
-- ============================================================

-- Extensão para gerar UUIDs
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- PERFIS / UTILIZADORES
-- ------------------------------------------------------------
create table profiles (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  funcao text,
  pin text not null,                     -- PIN de 4 dígitos (ver nota de segurança no fim)
  is_admin boolean default false,
  apenas_fecho_caixa boolean default false,
  areas text[] default '{}',             -- ex: '{Financeiro, ListaCompras}'
  criado_em timestamptz default now()
);

-- Registo simples de colaboradoras (nomes usados em pedidos/saídas)
create table colaboradoras_nomes (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  criado_em timestamptz default now()
);

-- Registo de fornecedores (Estoque > Registar compra)
create table fornecedores (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  criado_em timestamptz default now()
);

-- ------------------------------------------------------------
-- ESTOQUE & COMPRAS
-- ------------------------------------------------------------
create table produtos (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  categoria text default 'Geral',
  unidade text default 'un',
  estoque_minimo numeric default 0,
  estoque_atual numeric default 0,
  ativo boolean default true,
  criado_em timestamptz default now()
);

create table lista_compras (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid references produtos(id) on delete cascade,
  quantidade_solicitada numeric not null,
  solicitado_por uuid references profiles(id),
  solicitado_por_nome text,               -- nome livre (colaboradora partilhada)
  urgencia text default 'nao_urgente' check (urgencia in ('nao_urgente','urgente','emergencia')),
  status text default 'pendente' check (status in ('pendente','encomendado','entregue','em_estoque')),
  criado_em timestamptz default now()
);

create table compras (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid references produtos(id),
  lista_compra_id uuid references lista_compras(id),
  fornecedor text,
  quantidade numeric not null,
  preco_unitario numeric not null,
  preco_total numeric not null,
  comprado_por uuid references profiles(id),
  canal_pagamento text,                   -- 'Conta principal' | 'Online' | 'Dinheiro'
  pago boolean default false,             -- true = pago no momento do pedido
  data_compra date not null,
  data_prevista_entrega date,
  recebido boolean default false,
  confirmado_por uuid references profiles(id),
  confirmado_em timestamptz
);

create table entregas_estoque (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid references produtos(id),
  lista_compra_id uuid references lista_compras(id),
  quantidade numeric not null,
  entregue_por uuid references profiles(id),
  data_entrega date not null,
  recebido boolean default false,
  confirmado_por uuid references profiles(id),
  confirmado_em timestamptz
);

create table saidas_estoque (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid references produtos(id),
  quantidade numeric not null,
  retirado_por_nome text,
  para_equipa boolean default false,
  data date not null,
  criado_em timestamptz default now()
);

-- ------------------------------------------------------------
-- AFIAR ALICATES
-- ------------------------------------------------------------
create table alicates_afiar (
  id uuid primary key default uuid_generate_v4(),
  colaboradora text not null,
  quantidade integer not null,
  status text default 'pedido' check (status in ('pedido','entregue_amolador','devolvido','confirmado')),
  pago boolean default false,
  custo numeric,
  canal_pagamento text,
  data_pedido date not null,
  data_entregue_amolador date,
  data_devolvido date,
  data_confirmado date
);

-- ------------------------------------------------------------
-- FINANCEIRO
-- ------------------------------------------------------------
create table financeiro_movimentos (
  id uuid primary key default uuid_generate_v4(),
  tipo text not null check (tipo in ('entrada','saida')),
  categoria text not null,
  valor numeric not null,
  descricao text,
  produto_id uuid references produtos(id),
  origem text,                            -- 'fecho_caixa' | 'compra_estoque' | 'comissao' | 'afiacao' | 'manual' | 'pendente' | 'conta_pagar'
  canal_pagamento text,
  criado_por uuid references profiles(id),
  data date not null
);

create table fechos_caixa (
  id uuid primary key default uuid_generate_v4(),
  data date unique not null,
  dinheiro numeric default 0,
  cartao numeric default 0,
  online numeric default 0,
  criado_por uuid references profiles(id),
  criado_em timestamptz default now()
);

create table pendentes_pagamento (          -- Contas a receber
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  valor numeric not null,
  contacto text,
  data_prevista date,
  status text default 'pendente' check (status in ('pendente','pago')),
  canal_pagamento text,
  movimento_id uuid references financeiro_movimentos(id),
  criado_por uuid references profiles(id),
  criado_em timestamptz default now()
);

create table contas_pagar (
  id uuid primary key default uuid_generate_v4(),
  fornecedor text not null,
  categoria text,
  valor numeric not null,
  data_vencimento date,
  status text default 'pendente' check (status in ('pendente','pago')),
  canal_pagamento text,
  data_pagamento date,
  movimento_id uuid references financeiro_movimentos(id),
  criado_por uuid references profiles(id),
  criado_em timestamptz default now()
);

create table despesas_recorrentes (
  id uuid primary key default uuid_generate_v4(),
  fornecedor text not null,
  categoria text not null,
  valor numeric not null,
  dia_mes integer not null check (dia_mes between 1 and 28),
  ativo boolean default true
);

create table comissoes (
  id uuid primary key default uuid_generate_v4(),
  profissional text not null,
  mes text not null,                      -- 'YYYY-MM'
  faturacao_bruto numeric not null,
  status text default 'pendente' check (status in ('pendente','pago')),
  canal_pagamento text,
  criado_por uuid references profiles(id),
  criado_em timestamptz default now()
  -- comissão calculada em runtime: até 2460€ bruto @50%, acima @60% (sobre valor sem IVA, /1.23)
);

-- ------------------------------------------------------------
-- AGENDA
-- ------------------------------------------------------------
create table lista_espera (
  id uuid primary key default uuid_generate_v4(),
  cliente text not null,
  servico text,
  contacto text,
  data_preferida date,
  criado_em timestamptz default now()
);

-- ------------------------------------------------------------
-- MARKETING
-- ------------------------------------------------------------
create table conteudos_marketing (
  id uuid primary key default uuid_generate_v4(),
  tipo text,                              -- Post / Reel / Story / Campanha Ads
  titulo text,
  data date,
  status text default 'planeado' check (status in ('planeado','publicado')),
  criado_em timestamptz default now()
);

create table eventos_calendario (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  data date not null,
  campanha text,
  status text default 'planeado' check (status in ('planeado','em_curso','concluida','sem_campanha')),
  criado_em timestamptz default now()
);

create table investimentos_externos (
  id uuid primary key default uuid_generate_v4(),
  tipo text not null check (tipo in ('Anúncio','Parceria','Influencer','Offline')),
  nome text not null,
  detalhe text,                           -- plataforma / tipo de parceria / rede / local
  valor numeric default 0,
  retorno_clientes integer default 0,
  data date,
  status text default 'ativo' check (status in ('ativo','pausado','concluido')),
  criado_em timestamptz default now()
);

-- ------------------------------------------------------------
-- VENDAS
-- ------------------------------------------------------------
create table funis_vendas (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  etapas text,                            -- lista separada por vírgulas
  canal_origem text,
  novos_clientes integer default 0,
  status text default 'ativo' check (status in ('ativo','pausado')),
  criado_em timestamptz default now()
);

create table estrategias_vendas (
  id uuid primary key default uuid_generate_v4(),
  titulo text not null,
  objetivo text,
  data_inicio date,
  data_fim date,
  status text default 'planeada' check (status in ('planeada','em_curso','concluida')),
  valor_investido numeric default 0,
  resultado text,
  valor_gerado numeric default 0,
  criado_em timestamptz default now()
);

-- ------------------------------------------------------------
-- GESTÃO (tarefas)
-- ------------------------------------------------------------
create table tarefas (
  id uuid primary key default uuid_generate_v4(),
  titulo text not null,
  responsavel_nome text,
  data_inicio date,
  data_entrega date,
  urgencia text default 'media' check (urgencia in ('baixa','media','alta')),
  categoria text,
  coluna text default 'a_fazer' check (coluna in ('a_fazer','em_progresso','concluido')),
  criado_em timestamptz default now()
);

create table tarefas_recorrentes (
  id uuid primary key default uuid_generate_v4(),
  titulo text not null,
  frequencia text check (frequencia in ('semanal','quinzenal','mensal','trimestral','semestral','anual')),
  data_referencia date not null,
  categoria text,
  urgencia text default 'media'
);

-- ------------------------------------------------------------
-- CONFIGURAÇÕES GERAIS (metas do dashboard)
-- ------------------------------------------------------------
create table configuracoes (
  chave text primary key,
  valor numeric
);
insert into configuracoes (chave, valor) values
  ('limite_gastos_mensal', 1500),
  ('meta_mensal_vendas', 4000);

-- ============================================================
-- RLS — Row Level Security
-- Modelo simples: qualquer utilizador autenticado (via Supabase
-- Auth) tem acesso total. Como o controlo fino de "quem vê o quê"
-- já é feito na aplicação (perfis com PIN e áreas permitidas),
-- aqui só garantimos que só quem está autenticado entra.
-- ============================================================
alter table profiles enable row level security;
alter table colaboradoras_nomes enable row level security;
alter table fornecedores enable row level security;
alter table produtos enable row level security;
alter table lista_compras enable row level security;
alter table compras enable row level security;
alter table entregas_estoque enable row level security;
alter table saidas_estoque enable row level security;
alter table alicates_afiar enable row level security;
alter table financeiro_movimentos enable row level security;
alter table fechos_caixa enable row level security;
alter table pendentes_pagamento enable row level security;
alter table contas_pagar enable row level security;
alter table despesas_recorrentes enable row level security;
alter table comissoes enable row level security;
alter table lista_espera enable row level security;
alter table conteudos_marketing enable row level security;
alter table eventos_calendario enable row level security;
alter table investimentos_externos enable row level security;
alter table funis_vendas enable row level security;
alter table estrategias_vendas enable row level security;
alter table tarefas enable row level security;
alter table tarefas_recorrentes enable row level security;
alter table configuracoes enable row level security;

-- Política genérica: utilizador autenticado tem acesso total (CRUD)
do $$
declare
  t text;
begin
  for t in
    select unnest(array[
      'profiles','colaboradoras_nomes','fornecedores','produtos','lista_compras',
      'compras','entregas_estoque','saidas_estoque','alicates_afiar',
      'financeiro_movimentos','fechos_caixa','pendentes_pagamento','contas_pagar',
      'despesas_recorrentes','comissoes','lista_espera','conteudos_marketing',
      'eventos_calendario','investimentos_externos','funis_vendas',
      'estrategias_vendas','tarefas','tarefas_recorrentes','configuracoes'
    ])
  loop
    execute format('create policy "auth_full_access" on %I for all using (auth.role() = ''authenticated'') with check (auth.role() = ''authenticated'');', t);
  end loop;
end $$;

-- ============================================================
-- NOTA DE SEGURANÇA IMPORTANTE
-- ============================================================
-- Guardar o PIN em texto simples (coluna profiles.pin) é aceitável
-- só como controlo de conveniência entre colegas que partilham um
-- dispositivo — NÃO é uma proteção real contra acesso indevido.
-- Se um dia isto guardar dados sensíveis de clientes (saúde, cartões
-- de pagamento, etc.), o correto é usar o Supabase Auth verdadeiro
-- (email+password ou magic link) em vez de PINs de 4 dígitos.
-- ============================================================
