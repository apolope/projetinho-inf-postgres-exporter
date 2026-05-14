# projetinho-inf-postgres-exporter

Métricas detalhadas do PostgreSQL 16 + PostGIS para Prometheus, com queries
customizadas para locks, slow queries, bloat, geometrias e backup status.

**Entenda em 2 min** → leia este README.
**Rode localmente em 10 min** → siga a seção [Quick Start](#quick-start).
**Saiba onde está cada doc** → veja [Documentação](#documentação).

---

## O que este repositório faz

| Função | Detalhe |
|--------|---------|
| Exporter | `prometheuscommunity/postgres-exporter:v0.15.0` (imagem oficial, sem custom build) |
| Custom queries | 11 queries em `conf/queries.yaml` (PostGIS, locks, slow queries, bloat) |
| Métricas | Prometheus em `:9187/metrics` |
| Alertas | 7 alertas prontos para Prometheus |
| Dashboard | Grafana pronto para importar (`monitoring/grafana_dashboard.json`) |
| LGPD | Zero acesso a dados de aplicação — apenas catálogo do sistema |
| Role | `metrics_reader` com permissões mínimas (pg_monitor) |

---

## Quick Start

### Pré-requisitos

- Docker 24+ e Docker Compose v2
- Postgres 16 rodando na rede `coolify-network`
- Role `metrics_reader` criada (ver abaixo)

### 1. Crie o role no Postgres

```bash
# Execute no container do Postgres
docker exec -it postgres psql -U postgres -d postgres \
  -f /path/to/sql/create_metrics_role.sql

# Defina a senha
docker exec -it postgres psql -U postgres -c \
  "ALTER ROLE metrics_reader WITH PASSWORD 'senha_forte';"
```

### 2. Configure o ambiente

```bash
cp .env.example .env
# Edite .env: defina DATA_SOURCE_PASS com a senha acima
```

### 3. Suba o exporter

```bash
docker compose --env-file .env -f docker/docker-compose.yml up -d
```

### 4. Verifique

```bash
# Confirma que o exporter está respondendo
curl -s http://localhost:9187/metrics | grep pg_up

# Esperado: pg_up 1
```

---

## Métricas customizadas

| Query | O que mede |
|-------|-----------|
| `pg_database_size` | Tamanho de cada database |
| `pg_table_size` | Top 20 maiores tabelas |
| `pg_index_bloat` | Candidatos a REINDEX |
| `pg_stat_statements_top` | Top 10 slow queries (normalizado, LGPD-safe) |
| `pg_locks_count` | Locks por tipo |
| `pg_connections_by_state` | Conexões: active, idle, idle in transaction |
| `pg_long_running_queries` | Queries rodando > 30s |
| `pg_dead_tuples` | Candidatos a VACUUM |
| `postgis_geometry_count` | Tabelas com colunas geometry |
| `postgis_spatial_index_size` | Índices GiST espaciais |
| `pg_cache_hit_ratio` | Hit ratio por database (alvo: > 95%) |
| `pg_long_running_transactions` | Transações abertas > 10min |

Ver catálogo completo em [docs/METRICS.md](docs/METRICS.md).

---

## Grafana

Importe `monitoring/grafana_dashboard.json` no Grafana:

1. Grafana → Dashboards → Import
2. Upload JSON file → selecione `grafana_dashboard.json`
3. Selecione o datasource Prometheus
4. Save

O dashboard inclui: visão geral, tamanho por database, locks, cache hit ratio,
slow queries, PostGIS e status do backup (via métricas do pgbackrest-infra).

---

## Linting (antes de abrir PR)

```bash
yamllint conf/queries.yaml monitoring/prometheus_alerts.yaml
promtool check rules monitoring/prometheus_alerts.yaml
```

---

## Documentação

| Doc | Quando ler |
|-----|-----------|
| [docs/METRICS.md](docs/METRICS.md) | Catálogo completo de métricas |
| [docs/ALERTS.md](docs/ALERTS.md) | Cada alerta + ação de oncall |
| [docs/BASELINE.md](docs/BASELINE.md) | Valores de referência por estado da plataforma |
| [docs/LGPD.md](docs/LGPD.md) | Conformidade LGPD — sem dados pessoais |

---

## Contribuição

```bash
git checkout -b feat/nova-query
# adicione query em conf/queries.yaml
# documente em docs/METRICS.md
yamllint conf/queries.yaml
git commit -m "feat: adiciona métrica X"
# abra PR para main
```

Branch `main` protegida. PR requer review. Merge com squash.
