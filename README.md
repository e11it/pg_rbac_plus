# PostrgeSQL and PGmigrate

Ролевая модель для PostgreSQL и миграция схем с помощью PGmigrate.

## Как начать использовать

1. Склонировать репозиторий и перейти в него

2. Удалить пример базы dwh из директории migrations:
    ```bash
    rm -rf migrations/dwh
    ```

3. Поправить конфигурацию в [scripts/config.sh](./scripts/config.sh)
    ```
    # Имя базы данных
    DB="dwh"
    # Список требуемый схем
    declare -a SCHEMES=("raw" "ods" "cdm")
    ```

4. Сгенерировать структуру для PGmigrate
    ```bash
    # Будет создана новая структура в директории migrations
    bash scripts/create_pgmigrate_dirs.sh -p migrations
    ```

5. Создать миграцию и применить (см "как запустить пример")


## Как запустить пример

Запустить postgresql
```
docker-compose up -d
```

Создать новую базу данных
```
docker-compose exec -u postgres postgres psql -c 'CREATE DATABASE dwh';
```

Подключиться к БД с помощью psql

```
docker-compose exec -u postgres postgres psql
```

Создать схемы и базовую ролевую модель:
```
docker-compose exec -u postgres postgres /bin/bash /opt/scripts/create_schema.sh
```

Создать пользователя для выполнения миграций

```
docker-compose exec -u postgres postgres psql -c "create user pgmigrate with password '1234' in group dwh_raw_pgm,dwh_ods_pgm,dwh_cdm_pgm;"
```

```
docker-compose run pgmigrate bash /opt/scripts/do_migrate.sh
```

Остановить и очистить Volumes
```
docker-compose down -v
```
