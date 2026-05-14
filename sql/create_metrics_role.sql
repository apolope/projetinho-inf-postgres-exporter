-- create_metrics_role.sql
-- Cria o role metrics_reader com permissões mínimas para o postgres-exporter.
-- Execute como superuser (postgres) no banco 'postgres':
--   psql -U postgres -d postgres -f sql/create_metrics_role.sql
--
-- Role propositalmente sem LOGIN aqui — a senha é definida separadamente
-- para evitar que apareça no histórico de shell ou logs.
-- Defina a senha via:
--   ALTER ROLE metrics_reader WITH PASSWORD 'sua_senha_aqui';

-- Cria o role se não existir
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'metrics_reader') THEN
    CREATE ROLE metrics_reader WITH LOGIN;
    RAISE NOTICE 'Role metrics_reader criada.';
  ELSE
    RAISE NOTICE 'Role metrics_reader já existe — pulando criação.';
  END IF;
END
$$;

-- Permissões no banco postgres (catálogo do sistema)
GRANT CONNECT ON DATABASE postgres TO metrics_reader;

-- pg_stat_* views — leitura somente de catálogo de performance
GRANT pg_monitor TO metrics_reader;
-- pg_monitor inclui: pg_read_all_stats, pg_stat_scan_tables

-- pg_stat_statements — necessário para custom query de slow queries
-- A extensão deve estar ativa (já incluída no init/00_extensions.sql do Postgres)
GRANT SELECT ON pg_stat_statements TO metrics_reader;

-- Acesso a pg_locks (view, não tabela — não há dado de aplicação aqui)
-- Já incluído via pg_monitor, mas explicitamos para clareza

-- Acesso para contar geometrias PostGIS (metadados de catálogo, não dados)
-- metrics_reader pode fazer SELECT em pg_class, pg_attribute, pg_type via pg_catalog
-- Estes são acessíveis por qualquer role com CONNECT por padrão no Postgres.

-- NÃO conceder:
-- - SELECT em tabelas de aplicação (api_db, authentik_db, etc.)
-- - CREATE, INSERT, UPDATE, DELETE em qualquer objeto
-- - Superuser ou CREATEROLE

-- Verificação final
DO $$
DECLARE
  has_monitor BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT FROM pg_auth_members am
    JOIN pg_roles r ON r.oid = am.roleid
    JOIN pg_roles m ON m.oid = am.member
    WHERE r.rolname = 'pg_monitor'
      AND m.rolname = 'metrics_reader'
  ) INTO has_monitor;

  IF has_monitor THEN
    RAISE NOTICE 'OK: metrics_reader tem pg_monitor.';
  ELSE
    RAISE WARNING 'ATENÇÃO: metrics_reader não tem pg_monitor — verifique manualmente.';
  END IF;
END
$$;

-- Lembre de definir a senha após executar este script:
-- ALTER ROLE metrics_reader WITH PASSWORD 'senha_forte_aqui';
-- E atualize DATA_SOURCE_PASS no .env / Coolify.
