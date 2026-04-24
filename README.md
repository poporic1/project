# Source -> Stage

## Что делает проект

Проект поднимает локально:

- Source PostgreSQL с исходными данными
- DWH PostgreSQL
- Airflow

В DWH автоматически создается слой `stage`.
Далее доступны 2 DAG-а:

- `source_to_stage_full_reload` - полная перегрузка через `tmp`-таблицу и подмену таблицы
- `source_to_stage_incremental_load` - инкрементальная дозагрузка напрямую в `stage`

## Структура проекта

```text
project/
├─ .env
├─ docker-compose.yaml
├─ README.md
├─ airflow/
│  ├─ requirements.txt
│  └─ dags/
│     ├─ full_reload_dag.py
│     ├─ incremental_load_dag.py
│     ├─ common/
│     │  └─ stage_loader.py
│     ├─ ddl/                   # папка со скриптами создания объектов
│     │  └─ stage/
│     │     └─ create_stage_tables.sql
│     └─ dml/                   # папка скриптами взаимодействия с данными
│        └─ stage/
│           ├─ create_tmp_table.sql
│           ├─ load_all_source_data_to_tmp_table.sql
│           ├─ swap_tmp_table_with_stage_table.sql
│           └─ load_incremental_new_data_to_stage_table.sql
└─ source/                      # исходная база
```

## Структура исходных данных

В Source хранится одна таблица с заявками. Каждая строка - это состояние отдельной заявки
на конкретную дату загрузки.

Основные группы полей:

- идентификатор и описание заявки: `id`, `desc`
- даты жизненного цикла: `create_date`, `plan_date`, `close_date`
- место возникновения: `location`, `place`
- автор заявки: `author_id`, `author_nm`, `author_position`
- ответственный: `responsible_id`, `responsible_nm`, `responsible_position`
- состояние заявки: `status`, `critical`, `photo`, `escalated`, `estimated_value`
- дата снимка: `insert_dt`

Поле `insert_dt` используется как граница инкрементальной загрузки.

## Логика загрузки

### Полная перегрузка
1. Создается `stage.tmp_source_table`
2. В `tmp` загружаются все данные из Source
3. `tmp` подменяет `stage.source_table` через `rename`

### Инкрементальная загрузка
1. В `stage.source_table` ищется максимальное значение `insert_dt`
2. Из Source выбираются только строки с `insert_dt` больше этой даты
3. Новые строки напрямую вставляются в `stage.source_table`

## Как работает перенос между двумя PostgreSQL

Source и DWH - это две разные базы PostgreSQL. Поэтому проект не может использовать один
SQL вида `insert into dwh_table select ... from source_table` без дополнительных механизмов.

Под капотом используется такой процесс:

1. Python открывает соединение с Source и соединение с DWH
2. В Source создается именованный курсор
3. Курсор читает строки батчами через `fetchmany(BATCH_SIZE)`
4. Каждый батч сериализуется в CSV в памяти
5. DWH принимает этот батч через `copy_expert(... COPY ... FROM STDIN ...)`

За чтение батчами отвечает метод `fetchmany`.
За массовую запись в PostgreSQL отвечает метод `copy_expert`.

## Запуск

### 1. Поднять Source
```bash
cd source
docker compose up -d
```

### 2. Поднять DWH и Airflow
```bash
cd ..
docker compose up airflow-init
docker compose up -d
```

### 3. Открыть Airflow
- URL: `http://localhost:8080`
- Логин: `admin`
- Пароль: `admin`

## Что уже настроено

Airflow connections создаются через переменные окружения автоматически:

- `source_db`
- `dwh_db`

Ничего вручную в UI добавлять не нужно.
