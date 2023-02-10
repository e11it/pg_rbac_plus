# PostrgeSQL and PGmigrate

Ролевая модель для PostgreSQL и миграция схем с помощью PGmigrate.

## Содержимое


## Как начать использовать

Запустить postgresql
```
docker-compose up -d
```

Создать новую базу данных
```
docker-compose exec -u postgres postgres psql -c 'CREATE DATABASE dwh';
```

Подключиться к БД с помощью psql

docker-compose exec -u postgres postgres psql


Создать схемы и базовую ролевую модель:
```
docker-compose exec -u postgres postgres /bin/bash /opt/scripts/create_schema.sh
```

Создать пользователя для выполнения миграций

```
docker-compose exec -u postgres postgres psql -c "create user pgmigrate with password '1234' in group dwh_raw_sudo,dwh_ods_sudo,dwh_cdm_sudo;"
```

```
docker-compose run pgmigrate bash /opt/scripts/do_migrate.sh
```

Остановить и очистить Volumes
```
docker-compose down -v
```
