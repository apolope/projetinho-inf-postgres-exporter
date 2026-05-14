# Baseline de Métricas — projetinho-inf-postgres-exporter

Este documento registra os valores de referência esperados em diferentes estados
da plataforma. Use para detectar regressões e anomalias.

---

## Estado 0: Postgres vazio (sem aplicações conectadas)

Capturado em: 2026-05-13 (instalação inicial)
Banco com apenas estrutura base (PostGIS, roles, databases criados).

| Métrica | Valor esperado |
|---------|---------------|
| `pg_up` | 1 |
| `pg_database_size_size_bytes{datname="api_db"}` | ~10 MB (estrutura PostGIS) |
| `pg_database_size_size_bytes{datname="authentik_db"}` | ~8 MB |
| `pg_database_size_size_bytes{datname="glitchtip_db"}` | ~8 MB |
| `pg_database_size_size_bytes{datname="metabase_db"}` | ~8 MB |
| `pg_connections_by_state_count{state="active"}` | 1–2 (apenas exporter) |
| `pg_cache_hit_ratio_cache_hit_ratio_pct` | > 99% (banco vazio, tudo em cache) |
| `pg_long_running_queries_count` | 0 |
| `pg_long_running_transactions_count` | 0 |
| `pg_locks_count_count{mode="AccessShareLock"}` | 1–5 (locks internos) |
| `postgis_geometry_count_geometry_columns` | 0 (sem tabelas de aplicação ainda) |

---

## Estado 1: Authentik conectado

Após Authentik fazer suas migrations (cria tabelas de usuários/tokens/etc.).

| Métrica | Mudança esperada |
|---------|-----------------|
| `pg_database_size_size_bytes{datname="authentik_db"}` | ~50–100 MB |
| `pg_connections_by_state_count{state="idle"}` | +3–5 (pool do Authentik) |
| `pg_stat_user_tables` | +40–60 tabelas em authentik_db |

---

## Estado 2: API Spring Boot conectada

Após Flyway/Liquibase rodar as migrations do schema de monumentos.

| Métrica | Mudança esperada |
|---------|-----------------|
| `pg_database_size_size_bytes{datname="api_db"}` | +100–500 MB (depende dos dados de monumentos carregados) |
| `postgis_geometry_count_geometry_columns` | > 0 (tabelas com colunas geometry) |
| `postgis_spatial_index_size_size_bytes` | > 0 (índices GiST criados) |
| `pg_connections_by_state_count{state="idle"}` | +5–10 (pool Spring Boot via PgBouncer) |

---

## Estado 3: Carga normal de produção

Após 30 dias de uso com Authentik + API + Metabase.

| Métrica | Valor alvo |
|---------|-----------|
| `pg_cache_hit_ratio_cache_hit_ratio_pct` | > 95% |
| `pg_long_running_queries_count` | 0 (alerts disparando se > 10) |
| `pg_dead_tuples_dead_ratio_pct` | < 10% em todas as tabelas |
| `pg_connections_by_state_count{state="active"}` | < 20 em pico |
| `pg_stat_statements_top_mean_exec_time_ms` | < 100ms para queries OLTP |
| Crescimento de `api_db` | < 1 GB/mês estimado (ajustar após dados reais) |

---

## Como usar este documento

1. **Ao adicionar uma nova aplicação**: capture um snapshot das métricas antes e depois
   do primeiro deploy. Documente as mudanças esperadas aqui.

2. **Em investigação de incidente**: compare as métricas atuais com o baseline.
   Desvios grandes indicam a causa raiz.

3. **Planejamento de capacidade**: o crescimento de `pg_database_size` ao longo do
   tempo indica quando será necessário expandir o volume da VPS.

4. **Após VACUUM/REINDEX**: verifique que `dead_ratio_pct` voltou ao baseline e
   que `cache_hit_ratio` não degradou.
