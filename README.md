## Что делает проект

Проект поднимает:

- Source PostgreSQL
- DWH PostgreSQL
- Airflow

В DWH автоматически создаются слои:

- `stage` - слой с исходными данными
- `dds` - слой с очищенными и подготовленными данными
- `dm` - слой витрин

Доступны DAG-и:

- `source_to_stage_full_reload` - полная перегрузка Source -> Stage через `tmp`-таблицу
- `source_to_stage_incremental_load` - инкрементальная дозагрузка Source -> Stage
- `dds_load_currency` - загрузка курсов валют из API ЦБ РФ в `dds.dim_currency`
- `stage_to_dds_load` - загрузка данных из `stage` в DDS
- `dds_to_dm_load` - загрузка витрин из DDS в DM

## Структура проекта

```text
project/
├─ .env
├─ docker-compose.yaml
├─ README.md
├─ airflow/
│  ├─ create_dwh_objects.sql
│  ├─ requirements.txt
│  └─ dags/
│     ├─ stage_full_reload_dag.py
│     ├─ stage_incremental_load_dag.py
│     ├─ dds_load_currency_dag.py
│     ├─ stage_to_dds_load_dag.py
│     ├─ dds_to_dm_load_dag.py
│     ├─ etl/
│     │  ├─ dwh.py
│     │  ├─ stage_loader.py
│     │  └─ currency_loader.py
│     ├─ ddl/
│     │  ├─ create_ddl_objects.sql
│     │  ├─ stage/
│     │  │  ├─ schema_stage.sql
│     │  │  ├─ source_table.sql
│     │  │  └─ tmp_source_table.sql
│     │  ├─ dds/
│     │  │  ├─ schema_dds.sql
│     │  │  ├─ dim_position.sql
│     │  │  ├─ dim_employee.sql
│     │  │  ├─ dim_location.sql
│     │  │  ├─ dim_place.sql
│     │  │  ├─ dim_status.sql
│     │  │  ├─ dim_critical.sql
│     │  │  ├─ dim_currency.sql
│     │  │  ├─ fact_request.sql
│     │  │  └─ reject_fact_request.sql
│     │  └─ dm/
│     │     ├─ schema_dm.sql
│     │     ├─ dim_month.sql
│     │     ├─ dim_place_location.sql
│     │     ├─ dim_responsible.sql
│     │     ├─ dim_status.sql
│     │     ├─ fact_first_priority.sql
│     │     ├─ fact_metrics.sql
│     │     ├─ tmp_fact_first_priority.sql
│     │     └─ tmp_fact_metrics.sql
│     └─ dml/
│        ├─ create_dml_objects.sql
│        ├─ public/
│        │  └─ replace_table_with_tmp.sql
│        ├─ dds/
│        │  ├─ clean_string.sql
│        │  ├─ to_date_safe.sql
│        │  ├─ to_timestamp_safe.sql
│        │  ├─ load_dim_position.sql
│        │  ├─ load_dim_employee.sql
│        │  ├─ load_dim_location.sql
│        │  ├─ load_dim_place.sql
│        │  ├─ load_dim_status.sql
│        │  ├─ load_dim_critical.sql
│        │  └─ load_fact_request.sql
│        └─ dm/
│           ├─ load_dim_month.sql
│           ├─ load_dim_place_location.sql
│           ├─ load_dim_responsible.sql
│           ├─ load_dim_status.sql
│           ├─ load_fact_first_priority.sql
│           └─ load_fact_metrics.sql
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
1. Очищается `stage.tmp_source_table`
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

Служебная таблица:

- `dds.reject_fact_request` - строки, которые не прошли проверку качества данных

Справочники `dds.dim_position`, `dds.dim_employee`, `dds.dim_location`, `dds.dim_place`, `dds.dim_status`, `dds.dim_critical` загружаются как insert-only: новые значения добавляются, существующие не обновляются.

`dds.dim_currency` загружается отдельным DAG-ом через upsert: новая валюта вставляется, существующая обновляется.

`dds.fact_request` загружается как SCD2 по полным снапшотам. Процедура берет новые снапшоты из `stage.source_table`, очищает и типизирует строки, отбраковывает некорректные записи, сравнивает валидные строки с активными версиями в `dds.fact_request`, закрывает старые версии и вставляет новые. Заявки, которые были в предыдущем снапшоте, но отсутствуют в текущем, помечаются как удаленные.

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
5. Старые версии измененных заявок закрываются
6. Новые версии вставляются в `dds.fact_request`
7. Заявки, которых нет в текущем снапшоте, помечаются как удаленные

Поле `snapshot_date` используется как дата последнего снапшота, в котором была заявка.

## DM

DM хранит витрины для аналитики.
DAG - `dds_to_dm_load`

В DM создаются справочники:

- `dm.dim_month` - месяцы для витрин
- `dm.dim_place_location` - связка места и локации
- `dm.dim_responsible` - ответственные сотрудники
- `dm.dim_status` - статусы заявок

Основные таблицы фактов:

- `dm.fact_first_priority` - заявки, требующие особого внимания
- `dm.fact_metrics` - расчетные метрики по заявкам

Служебные таблицы:

- `dm.tmp_fact_first_priority` - новый набор данных для `dm.fact_first_priority`
- `dm.tmp_fact_metrics` - новый набор данных для `dm.fact_metrics`

Справочники DM перегружаются через `TRUNCATE + INSERT`.

Факты DM пересчитываются полностью: сначала новый набор данных пишется в `tmp`-таблицу, затем целевая таблица подменяется через `public.replace_table_with_tmp`.

## Расписание DAG-ов

Ежедневная цепочка:

```text
07:00 - source_to_stage_incremental_load
08:00 - dds_load_currency
08:30 - stage_to_dds_load
09:00 - dds_to_dm_load
```

`source_to_stage_full_reload` запускается вручную, когда нужно полностью перегрузить Stage.

Связь между DAG-ами сделана через расписание.

## Создание объектов БД

Объекты создаются автоматически при первом запуске контейнера DWH.

Главный файл:

```text
airflow/create_dwh_objects.sql
```

Он запускает:

```text
dags/ddl/create_ddl_objects.sql
dags/dml/create_dml_objects.sql
```

DDL-скрипты создают схемы и таблицы Stage, DDS и DM.
DML-скрипты создают функции и процедуры для загрузок.

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
