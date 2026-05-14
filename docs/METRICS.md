# Catálogo de Métricas — projetinho-inf-postgres-exporter

## Métricas padrão (postgres-exporter)

As métricas padrão do `prometheuscommunity/postgres-exporter` incluem:

| Métrica | Tipo | Descrição |
|---------|------|-----------|
| `pg_up` | Gauge | 1 se o exporter consegue conectar ao Postgres, 0 caso contrário |
| `pg_settings_*` | Gauge | Parâmetros de configuração do Postgres (shared_buffers, max_connections, etc.) |
| `pg_stat_bgwriter_*` | Counter | Estatísticas do background writer |
| `pg_stat_database_*` | Counter/Gauge | Estatísticas por database (commits, rollbacks, blocos lidos, etc.) |
| `pg_stat_replication_*` | Gauge | Estado da replicação (se ativa) |

## Métricas customizadas (conf/queries.yaml)

### Tamanho por database

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_database_size_size_bytes` | `datname` | Gauge | Tamanho total do database em bytes |

### Tamanho por tabela (top 20)

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_table_size_total_bytes` | `schema`, `table` | Gauge | Tamanho total (tabela + TOAST + índices) |
| `pg_table_size_table_bytes` | `schema`, `table` | Gauge | Tamanho da tabela sem índices |
| `pg_table_size_indexes_bytes` | `schema`, `table` | Gauge | Tamanho apenas dos índices |

### Bloat de índices

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_index_bloat_bloat_ratio_pct` | `schema`, `index_name` | Gauge | Ratio estimado de bloat (%) |
| `pg_index_bloat_idx_scan` | `schema`, `index_name` | Counter | Scans pelo índice |

### Top queries (pg_stat_statements)

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_stat_statements_top_total_exec_time_ms` | `queryid` | Gauge | Tempo total de execução em ms |
| `pg_stat_statements_top_mean_exec_time_ms` | `queryid` | Gauge | Tempo médio de execução em ms |
| `pg_stat_statements_top_calls` | `queryid` | Counter | Número de execuções |
| `pg_stat_statements_top_rows` | `queryid` | Counter | Total de linhas processadas |

**Nota LGPD**: `queryid` é um hash normalizado — não contém valores literais de dados.

### Locks

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_locks_count_count` | `mode` | Gauge | Número de locks por tipo |

### Conexões

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_connections_by_state_count` | `state` | Gauge | Conexões por estado |

Estados possíveis: `active`, `idle`, `idle in transaction`, `idle in transaction (aborted)`, `fastpath function call`, `disabled`.

### Queries longas

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_long_running_queries_count` | — | Gauge | Queries rodando há > 30s |

### Dead tuples (top 20)

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_dead_tuples_dead_ratio_pct` | `schema`, `table` | Gauge | % de dead tuples |
| `pg_dead_tuples_n_dead_tup` | `schema`, `table` | Gauge | Número de dead tuples |
| `pg_dead_tuples_n_live_tup` | `schema`, `table` | Gauge | Número de live tuples |

### PostGIS

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `postgis_geometry_count_geometry_columns` | `schema`, `table` | Gauge | Colunas geometry por tabela |
| `postgis_spatial_index_size_size_bytes` | `schema`, `index_name` | Gauge | Tamanho de índices GiST |

### Cache hit ratio

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_cache_hit_ratio_cache_hit_ratio_pct` | `datname` | Gauge | % de blocos servidos do cache (alvo: > 95%) |

### Transações longas

| Métrica | Labels | Tipo | Descrição |
|---------|--------|------|-----------|
| `pg_long_running_transactions_count` | — | Gauge | Transações abertas há > 10min |

## Métricas do pgBackRest (porta 9854)

Coletadas pelo `pgbackrest-infra` e disponíveis no mesmo Prometheus:

| Métrica | Labels | Descrição |
|---------|--------|-----------|
| `pgbackrest_last_backup_timestamp_seconds` | `type`, `repo` | Timestamp do último backup |
| `pgbackrest_backup_size_bytes` | `type`, `repo` | Tamanho do último backup |
| `pgbackrest_last_verify_status` | `repo` | 0=ok, 1=falha |
| `pgbackrest_wal_archive_lag_seconds` | — | Atraso no arquivo WAL |
