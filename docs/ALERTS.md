# Alertas — projetinho-inf-postgres-exporter

Cada alerta inclui a condição de disparo, severidade, e ação esperada do oncall.

---

## PostgresDown {#PostgresDown}

**Severidade**: critical
**Condição**: `pg_up == 0` por 2 minutos

**O que significa**: o postgres-exporter não consegue conectar ao Postgres.
Pode ser queda do container, falha de rede Docker, ou credenciais inválidas.

**Ação**:
1. `docker ps | grep postgres` — container rodando?
2. `docker logs postgres --tail 50` — mensagem de erro?
3. `docker exec postgres pg_isready` — responde?
4. Verifique coolify-network: `docker network inspect coolify-network`
5. Se o Postgres caiu: `docker start postgres` ou restaure via pgBackRest.

---

## PostgresHighConnections {#PostgresHighConnections}

**Severidade**: warning
**Condição**: conexões totais > 80% de `max_connections` por 5 minutos

**O que significa**: o pool de conexões está quase saturado.
Em produção, `max_connections` normalmente é 100–200; PgBouncer deveria absorver picos.

**Ação**:
1. `SELECT count(*), state FROM pg_stat_activity GROUP BY state;`
2. Verifique se o PgBouncer está funcionando: `docker ps | grep pgbouncer`
3. Identifique conexões idle longas: `SELECT pid, usename, application_name, state, query_start FROM pg_stat_activity WHERE state = 'idle' ORDER BY query_start;`
4. Termine conexões idle problemáticas: `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND query_start < now() - interval '1 hour';`

---

## PostgresSlowQueries {#PostgresSlowQueries}

**Severidade**: warning
**Condição**: mais de 10 queries rodando há > 30s por 5 minutos

**O que significa**: queries lentas podem indicar lock contention, índices faltando,
ou carga anormal.

**Ação**:
1. `SELECT pid, query, query_start, state FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '30 seconds';`
2. Verifique locks: `SELECT * FROM pg_locks WHERE NOT granted;`
3. Se for lock wait: identifique o bloqueador e decida se termina o processo.
4. Se for query cara: analise com `EXPLAIN (ANALYZE, BUFFERS)`.

---

## PostgresDiskSpaceLow {#PostgresDiskSpaceLow}

**Severidade**: critical
**Condição**: espaço livre no volume do Postgres < 20% por 10 minutos

**O que significa**: risco iminente de crash por disco cheio.
Postgres para de aceitar escritas quando o disco enche (WAL não pode ser escrito).

**Ação** (urgente):
1. Identifique o que está consumindo espaço: `du -sh /var/lib/postgresql/data/*`
2. Limpe WAL órfão: `SELECT pg_switch_wal();` + pgBackRest archive-push
3. Execute VACUUM nas maiores tabelas: `VACUUM FULL <tabela>;` (libera espaço)
4. Expanda o volume no Coolify/Hostinger se necessário
5. Considere arquivar tabelas históricas

---

## PostgresDeadTuplesHigh {#PostgresDeadTuplesHigh}

**Severidade**: warning
**Condição**: qualquer tabela com > 20% de dead tuples por 30 minutos

**O que significa**: autovacuum não está acompanhando a taxa de writes,
ou foi desabilitado. Dead tuples consumem espaço e degradam queries.

**Ação**:
1. `VACUUM ANALYZE <schema>.<tabela>;` (manual, não bloqueia leitura)
2. Se urgente: `VACUUM FULL <schema>.<tabela>;` (bloqueia tabela — use com cuidado)
3. Verifique autovacuum: `SELECT * FROM pg_stat_user_tables WHERE relname = '<tabela>';`
4. Considere ajustar `autovacuum_vacuum_scale_factor` para tabelas de alta escrita.

---

## PostgresLongRunningTransaction {#PostgresLongRunningTransaction}

**Severidade**: warning
**Condição**: qualquer transação aberta há > 10 minutos

**O que significa**: transação longa bloqueia VACUUM, pode causar table bloat
e aumentar o WAL retention. Em sistemas com PostGIS, pode travar operações de escrita geoespacial.

**Ação**:
1. `SELECT pid, usename, xact_start, state, query FROM pg_stat_activity WHERE xact_start < now() - interval '10 minutes';`
2. Identifique se é esperado (batch job?) ou acidente (sessão abandonada)
3. Se for acidente: `SELECT pg_terminate_backend(<pid>);`
4. Investigue a causa raiz: erro de aplicação que não faz commit/rollback?

---

## PostgresCacheHitRatioLow {#PostgresCacheHitRatioLow}

**Severidade**: warning
**Condição**: cache hit ratio < 95% por 10 minutos

**O que significa**: muitas leituras indo ao disco em vez de memória.
Para dados PostGIS com geometrias grandes, pode ser esperado em queries de exportação;
para operações OLTP normais, indica falta de `shared_buffers` ou working set maior que a RAM.

**Ação**:
1. Verifique o database afetado: `pg_cache_hit_ratio_cache_hit_ratio_pct{datname=...}`
2. Identifique queries com full scans: `SELECT query, shared_blks_read FROM pg_stat_statements ORDER BY shared_blks_read DESC LIMIT 10;`
3. Se for tendência: considere aumentar `shared_buffers` (atualmente configurado no repo do Postgres)
4. Se for pico pontual de exportação: pode ser ignorado temporariamente.
