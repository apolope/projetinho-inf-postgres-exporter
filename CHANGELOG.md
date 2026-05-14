# Changelog — projetinho-inf-postgres-exporter

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).
Versionamento semântico conforme [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] — 2026-05-13

### Added
- `docker/docker-compose.yml` com `prometheuscommunity/postgres-exporter:v0.15.0`
- Sem Dockerfile custom — queries customizadas via volume (ver docker/README.md)
- `conf/queries.yaml` com 11 custom queries:
  - `pg_database_size`: tamanho por database
  - `pg_table_size`: top 20 maiores tabelas
  - `pg_index_bloat`: candidatos a REINDEX
  - `pg_stat_statements_top`: top 10 queries por tempo total
  - `pg_locks_count`: locks por tipo
  - `pg_connections_by_state`: conexões por estado
  - `pg_long_running_queries`: queries > 30s
  - `pg_dead_tuples`: candidatos a VACUUM
  - `postgis_geometry_count`: tabelas com colunas geometry
  - `postgis_spatial_index_size`: índices GiST espaciais
  - `pg_cache_hit_ratio`: hit ratio por database
  - `pg_long_running_transactions`: transações > 10min
- `sql/create_metrics_role.sql` — role `metrics_reader` com permissões mínimas
- `monitoring/prometheus_alerts.yaml` — 7 alertas (Down, HighConnections, SlowQueries, DiskSpaceLow, DeadTuplesHigh, LongRunningTransaction, CacheHitRatioLow)
- `monitoring/grafana_dashboard.json` — dashboard "Postgres Operacional" com 17 painéis
- CI: `lint.yml` (yamllint, promtool, queries schema validation, gitleaks, docker pull)
- Docs: METRICS.md, ALERTS.md, BASELINE.md, LGPD.md
- `.env.example` com variáveis documentadas

[0.1.0]: https://github.com/org/projetinho-inf-postgres-exporter/releases/tag/v0.1.0
