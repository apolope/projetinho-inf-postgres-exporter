# LGPD — projetinho-inf-postgres-exporter

## Declaração de conformidade

Este documento declara explicitamente que o `projetinho-inf-postgres-exporter` **não expõe
dados pessoais** através de métricas Prometheus.

---

## O que o exporter coleta

O `prometheuscommunity/postgres-exporter` e as custom queries em `conf/queries.yaml`
acessam exclusivamente:

| Fonte | Conteúdo | Dados pessoais? |
|-------|---------|----------------|
| `pg_database` | Nomes de databases e tamanhos | Não |
| `pg_tables` / `pg_class` | Nomes de tabelas e schemas | Não |
| `pg_stat_user_tables` | Estatísticas de uso (contagens, timestamps) | Não |
| `pg_stat_user_indexes` | Estatísticas de índices (scan counts, tamanhos) | Não |
| `pg_stat_statements` | Queries normalizadas (sem literais) e seus tempos | Não* |
| `pg_locks` | Tipos e contagens de locks | Não |
| `pg_stat_activity` | Estados de conexão e duração de queries | Não** |
| `pg_stat_database` | Estatísticas de blocos e transações por database | Não |
| `pg_attribute` / `pg_type` | Tipos de colunas (ex: geometry) | Não |

**\* pg_stat_statements**: o Postgres normaliza automaticamente os valores literais
em queries — `SELECT * FROM t WHERE id = 42` vira `SELECT * FROM t WHERE id = $1`.
Nenhum valor de dado de usuário aparece no `queryid` ou no texto de query coletado.

**\*\* pg_stat_activity**: o exporter coleta apenas `state` e contagens — **não**
o texto das queries em execução. A coluna `query` não é exposta nas métricas.

---

## O que o exporter NÃO acessa

- Conteúdo de nenhuma tabela de aplicação (`api_db`, `authentik_db`, etc.)
- Dados de usuários, tokens, sessões ou quaisquer dados pessoais
- O exporter tem permissão apenas de `SELECT` em views de catálogo do sistema
  via o role `metrics_reader` com `pg_monitor`

---

## Role e permissões

O role `metrics_reader` (criado via `sql/create_metrics_role.sql`) tem:

- `CONNECT` no banco `postgres` (apenas catálogo do sistema)
- Membership em `pg_monitor` (acesso a `pg_stat_*`, `pg_locks`)
- **Sem** acesso a nenhum banco de aplicação (`api_db`, `authentik_db`, etc.)
- **Sem** `SELECT` em tabelas de aplicação

---

## Retenção de métricas no Prometheus

As métricas são séries temporais numéricas sem conteúdo de dados pessoais.
A retenção no Prometheus deve ser configurada conforme a política de dados da organização.
Recomenda-se 90 dias para análise de tendências.

---

## Conclusão

O `projetinho-inf-postgres-exporter` é um componente de observabilidade de infraestrutura.
Ele monitora a saúde do sistema de banco de dados, não os dados armazenados nele.
**Não há possibilidade de vazamento de dados pessoais via métricas** deste repositório.

Responsável técnico: equipe de infra — Monumentos Públicos
Data de revisão: 2026-05-13
Próxima revisão: 2027-05-13
