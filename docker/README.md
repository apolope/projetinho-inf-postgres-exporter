# Por que não construímos uma imagem Docker custom?

`projetinho-inf-postgres-exporter` usa a imagem oficial
`prometheuscommunity/postgres-exporter` sem modificações.

## Motivo

O postgres-exporter aceita um arquivo de queries customizadas via
`PG_EXPORTER_EXTEND_QUERY_PATH` — todas as métricas específicas do projeto
ficam em `conf/queries.yaml`, montado como volume read-only.

Construir uma imagem custom implicaria:
1. Manter um Dockerfile que apenas adiciona um arquivo YAML
2. Rebuild a cada atualização de versão do exporter
3. Overhead de CI sem ganho real de segurança ou funcionalidade

A imagem oficial é assinada, publicada no Docker Hub e atualizada regularmente
pelo time do Prometheus. Pinamos a versão (`v0.15.0`) para builds reproduzíveis.

## Atualização de versão

Para atualizar o exporter:
1. Verifique o changelog em https://github.com/prometheus-community/postgres_exporter/releases
2. Atualize a tag em `docker/docker-compose.yml`
3. Teste as custom queries com a nova versão
4. Abra PR com `chore: bump postgres-exporter to vX.Y.Z`
