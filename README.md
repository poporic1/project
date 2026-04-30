## Что делает проект

Проект поднимает:

- Source PostgreSQL
- DWH PostgreSQL
- Airflow

В DWH автоматически создаются слои:

- `stage` - слой с исходными данными
- `dds` - слой с очищенными и подготовленными данными

Доступны DAG-и:

- `source_to_stage_full_reload` - полная перегрузка Source -> Stage через `tmp`-таблицу
- `source_to_stage_incremental_load` - инкрементальная дозагрузка Source -> Stage
- `dds_load_currency` - загрузка курсов валют из API ЦБ РФ в `dds.dim_currency`
- `stage_to_dds_load` - загрузка данных из `stage` в DDS

## Структура проекта

```text
project/
├─ .env
├─ docker-compose.yaml
├─ README.md
├─ airflow/
│  ├─ requirements.txt
│  └─ dags/
│     ├─ create_all_db_objects.sql
│     ├─ stage_full_reload_dag.py
│     ├─ stage_incremental_load_dag.py
│     ├─ dds_load_currency_dag.py
│     ├─ stage_to_dds_load_dag.py
│     ├─ common/
│     │  ├─ stage_loader.py
│     │  ├─ currency_loader.py
│     │  └─ dds_loader.py
│     ├─ ddl/
│     │  ├─ stage/
│     │  │  ├─ create_stage_objects.sql
│     │  │  └─ create_stage_tables.sql
│     │  └─ dds/
│     │     ├─ create_dds_objects.sql
│     │     ├─ schema_dds.sql
│     │     ├─ dim_position.sql
│     │     ├─ dim_employee.sql
│     │     ├─ dim_location.sql
│     │     ├─ dim_place.sql
│     │     ├─ dim_status.sql
│     │     ├─ dim_critical.sql
│     │     ├─ dim_currency.sql
│     │     ├─ fact_request.sql
│     │     ├─ reject_fact_request.sql
│     │     └─ tmp_fact_request_rows.sql
│     └─ dml/
│        ├─ stage/
│        │  ├─ create_tmp_table.sql
│        │  ├─ load_all_source_data_to_tmp_table.sql
│        │  ├─ swap_tmp_table_with_stage_table.sql
│        │  └─ load_incremental_new_data_to_stage_table.sql
│        └─ dds/
│           ├─ create_dds_objects.sql
│           ├─ clean_string.sql
│           ├─ to_date_safe.sql
│           ├─ to_timestamp_safe.sql
│           ├─ load_dim_position.sql
│           ├─ load_dim_employee.sql
│           ├─ load_dim_location.sql
│           ├─ load_dim_place.sql
│           ├─ load_dim_status.sql
│           ├─ load_dim_critical.sql
│           └─ load_fact_request.sql
└─ source/
```

## Структура исходных данных

В Source хранится одна таблица с заявками. Каждая строка - это состояние отдельной заявки на конкретную дату загрузки.

Основные группы полей:

- идентификатор и описание заявки: `id`, `desc`
- даты жизненного цикла: `create_date`, `plan_date`, `close_date`
- место возникновения: `location`, `place`
- автор заявки: `author_id`, `author_nm`, `author_position`
- ответственный: `responsible_id`, `responsible_nm`, `responsible_position`
- состояние заявки: `status`, `critical`, `photo`, `escalated`, `estimated_value`
- дата снапшота: `insert_dt`

## Stage

Stage хранит данные в том виде, в котором они пришли из Source. Для этого реализованы два варианта загрузки - полная перегрузка и инкрементальная загрузка.

### Полная перегрузка
DAG - `source_to_stage_full_reload`
Данные из Source полностью перегружаются в Stage. Используется для первого запуска.

Логика работы такая:
1. Создается `stage.tmp_source_table`
2. В `tmp` загружаются все данные из Source
3. `tmp` подменяет `stage.source_table` через `rename`

`tmp`-таблица нужна, чтобы основная таблица `stage.source_table` была недоступна минимальное время. Долгая загрузка идет во временную таблицу, а замена основной таблицы выполняется быстрым `rename`.

### Инкрементальная загрузка
DAG - `source_to_stage_incremental_load`
Берутся только новые данные из Source, которых нет на Stage, и дозагружаются в Stage. Используется для ежедневной загрузки.

Логика работы такая:
1. В `stage.source_table` ищется максимальное значение `insert_dt`
2. Из Source выбираются только строки с `insert_dt` больше этой даты
3. Новые строки напрямую вставляются в `stage.source_table`

## Особенности загрузки Source -> Stage

1. Python открывает соединение с Source и соединение с DWH
2. В Source создается именованный курсор
3. Курсор читает строки `батчами` через `fetchmany(BATCH_SIZE)`, чтобы не убить память
4. Каждый батч сериализуется в CSV в памяти (с памятью все будет нормально тк каждый батч ограничен размером `BATCH_SIZE`)
5. DWH принимает батч через `copy_expert(... COPY ... FROM STDIN ...)`

## DDS

DDS хранит очищенные и подготовленные данные.
DAG - `stage_to_dds_load`

В DDS создаются справочники:

- `dds.dim_position` - должности сотрудников
- `dds.dim_employee` - сотрудники
- `dds.dim_location` - укрупненные локации
- `dds.dim_place` - конкретные места внутри локаций
- `dds.dim_status` - статусы заявок
- `dds.dim_critical` - критичность заявок
- `dds.dim_currency` - курсы валют

Основная таблица фактов:

- `dds.fact_request`

Служебные таблицы:

- `dds.reject_fact_request` - строки, которые не прошли проверку качества данных
- `dds.tmp_fact_request_rows` - рабочая таблица для подготовки новых и измененных версий факта


### DQ-проверки и решения

| № | Проверка | Что найдено | SQL для поиска | Решение | SQL для проверки |
|---:|---|---|---|---|---|
| 1 | Дубликаты по заявке в одном снапшоте | Найдены дубликаты по `id = 4626` за `insert_dt = 2025-06-30` и `2025-06-29` | `select insert_dt, id, count(*) from stage.source_table group by id, insert_dt having count(*) > 1;` | Один из дублей загружается в `dds.fact_request`, второй переносится в `dds.reject_fact_request` | `select * from dds.fact_request where request_id = 4626;`<br><br>`select * from dds.reject_fact_request where id = '4626';` |
| 2 | Спецсимволы в `desc` | В поле `desc` найдены HTML-теги, HTML-сущности и знак абзаца | `SELECT id, "desc" FROM stage.source_table WHERE "desc" ~ '[^0-9A-Za-zА-Яа-я ,\.\-()]';` | Лишние символы очищаются при загрузке в DDS | `SELECT "desc" FROM dds.fact_request WHERE "desc" ~ '[^0-9A-Za-zА-Яа-я ,\.\-()]';` |
| 3 | Нарушение логики дат | Найдены заявки, где дата закрытия раньше даты создания: `close_date < create_date` | `SELECT count(*) FROM stage.source_table WHERE dds.to_timestamp_safe(create_date)::date > dds.to_date_safe(close_date);` | Такие записи считаются некорректными и переносятся в `dds.reject_fact_request` | `SELECT * FROM dds.fact_request WHERE create_date::date > close_date;` |
| 4 | Некорректное значение `place`, `id = 29081` | В поле `place` найдено нестандартное значение: `за красным шкафом у лестницы (слева)` | `SELECT place FROM stage.source_table WHERE id = '29081';` | Запись переносится в `dds.reject_fact_request` и не загружается в `dds.fact_request` | `SELECT place_id FROM dds.fact_request WHERE request_id = 29081;` |
| 5 | Некорректная связка `location` и `place`, `id = 28428` | Для `location = Ресторан` указано неподходящее значение `place = Вольер Ламы` | `SELECT * FROM stage.source_table WHERE id = '28428';` | Запись переносится в `dds.reject_fact_request` и не загружается в `dds.fact_request` | `SELECT * FROM dds.fact_request WHERE request_id = 28428;` |
| 6 | Пустые значения в `estimated_value` | В `stage.source_table` найдены пустые значения стоимости устранения проблемы | `select count(*) from stage.source_table where estimated_value = '';` | Пустые значения `estimated_value` при загрузке в DDS заменяются на `0` | `select count(*) from dds.fact_request where estimated_value is null;` |

## Загрузка валют

DAG - `dds_load_currency`
`dds.dim_currency` загружается отдельным DAG-ом из API ЦБ РФ.

Загрузка выполняется через upsert:

- если валюта новая, она вставляется
- если валюта уже есть, обновляются курс, номинал, название и дата обновления

## Загрузка факта

`dds.fact_request` хранит историю состояния заявок.

Логика загрузки:

1. Процедура обрабатывает новые снапшоты из `stage.source_table`
2. Строки очищаются и приводятся к DDS-типам
3. Некорректные строки уходят в `dds.reject_fact_request`
4. Валидные строки сравниваются с активной версией в `dds.fact_request`
5. Новые и измененные заявки попадают в `dds.tmp_fact_request_rows`
6. Старые версии измененных заявок закрываются
7. Новые версии вставляются в `dds.fact_request`
8. Заявки, которых нет в текущем снапшоте, помечаются как удаленные

Поле `snapshot_date` используется как дата последнего снапшота, в котором была заявка.

## Расписание DAG-ов

Ежедневная цепочка:

```text
07:00 - source_to_stage_incremental_load
08:00 - dds_load_currency
08:30 - stage_to_dds_load
```

`source_to_stage_full_reload` запускается вручную, когда нужно полностью перегрузить Stage.

Связь между DAG-ами сделана через расписание.

## Создание объектов БД

Объекты создаются автоматически при первом запуске контейнера DWH.

Главный файл:

```text
airflow/dags/create_all_db_objects.sql
```

Он запускает:

```text
ddl/stage/create_stage_objects.sql
ddl/dds/create_dds_objects.sql
dml/dds/create_dds_objects.sql
```

DDL-скрипты создают схемы и таблицы.
DML-скрипты в `dml/dds` создают функции и процедуры DDS.

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
- Ввести логин
- Ввести пароль

## Пересоздание DWH с нуля

Если нужно заново выполнить init-скрипты создания объектов:

```bash
docker compose down -v
docker compose up airflow-init
docker compose up -d
```