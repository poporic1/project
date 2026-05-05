from __future__ import annotations

import csv
import io
import logging
from typing import Any

from airflow.providers.postgres.hooks.postgres import PostgresHook

from etl.dwh import DWH_CONN_ID, execute_dwh_sql


logger = logging.getLogger(__name__)

BATCH_SIZE = 10_000

SOURCE_CONN_ID = "source_db"

STAGE_TABLE = "stage.source_table"
TMP_STAGE_TABLE = "stage.tmp_source_table"


def get_last_insert_dt() -> str | None:
    """
    Возвращает максимальное значение insert_dt из stage.source_table.

    :return: Последнее значение insert_dt или None, если таблица пустая.
    :rtype: str | None
    """
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                select max(insert_dt)
                from stage.source_table;
                """
            )
            value = cursor.fetchone()[0]

        logger.info(
            "Максимальное значение insert_dt в %s: %s", STAGE_TABLE, value
        )
        return value
    finally:
        conn.close()


def copy_rows_between_databases(
    select_sql: str,
    select_params: dict[str, Any] | None,
    target_table: str,
) -> int:
    """
    Переносит данные из Source PostgreSQL в DWH PostgreSQL батчами.

    :param select_sql: SQL-запрос к Source.
    :type select_sql: str
    :param select_params: Параметры SQL-запроса к Source.
    :type select_params: dict[str, Any] | None
    :param target_table: Полное имя таблицы в DWH.
    :type target_table: str
    :return: Число загруженных строк.
    :rtype: int
    :raises Exception: Если перенос завершился ошибкой.
    """
    logger.info("Начинаю перенос данных в таблицу %s", target_table)

    source_conn = PostgresHook(postgres_conn_id=SOURCE_CONN_ID).get_conn()
    dwh_conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    source_cursor = None
    total_rows = 0

    try:
        # именованный курсор читает данные из Source батчами
        source_cursor = source_conn.cursor(name="source_stream_cursor")
        source_cursor.itersize = BATCH_SIZE
        source_cursor.execute(select_sql, select_params)

        with dwh_conn.cursor() as dwh_cursor:
            while True:
                rows = source_cursor.fetchmany(BATCH_SIZE)

                if not rows:
                    break

                # текущий батч передается в COPY как CSV-поток в памяти
                buffer = io.StringIO()
                writer = csv.writer(buffer)

                for row in rows:
                    writer.writerow(
                        [r"\N" if value is None else value for value in row]
                    )

                buffer.seek(0)

                dwh_cursor.copy_expert(
                    f"""
                    copy {target_table}
                    from stdin with (format csv, null '\\N')
                    """,
                    buffer,
                )

                total_rows += len(rows)

                logger.info(
                    "Загружен батч: %s строк. Всего: %s",
                    len(rows),
                    total_rows,
                )

        dwh_conn.commit()

        logger.info(
            "Перенос в таблицу %s завершен. Всего строк: %s",
            target_table,
            total_rows,
        )

        return total_rows
    except Exception:
        dwh_conn.rollback()
        logger.exception(
            "Ошибка при переносе данных в таблицу %s", target_table
        )
        raise
    finally:
        try:
            if source_cursor is not None:
                source_cursor.close()
        except Exception:
            logger.exception("Не удалось закрыть курсор Source")

        source_conn.close()
        dwh_conn.close()


def load_all_source_data_to_tmp_table() -> None:
    """
    Загружает все данные из Source в stage.tmp_source_table.

    :return: None
    :rtype: None
    """
    logger.info("Начинаю полную загрузку Source -> %s", TMP_STAGE_TABLE)

    # очистка временной таблицы перед загрузкой
    execute_dwh_sql("truncate table stage.tmp_source_table;")

    loaded_rows = copy_rows_between_databases(
        select_sql="""
            select
                  id
                , "desc"
                , create_date
                , plan_date
                , "location"
                , place
                , author_id
                , author_nm
                , author_position
                , responsible_id
                , responsible_nm
                , responsible_position
                , status
                , close_date
                , estimated_value
                , critical
                , photo
                , escalated
                , insert_dt
            from source_data.source_table
            order by insert_dt, id;
        """,
        select_params=None,
        target_table=TMP_STAGE_TABLE,
    )

    logger.info(
        "Полная загрузка в tmp-таблицу завершена. Загружено строк: %s",
        loaded_rows,
    )


def load_incremental_new_data_to_stage_table() -> None:
    """
    Дозагружает новые строки из Source напрямую в stage.source_table.

    :return: None
    :rtype: None
    """
    logger.info("Начинаю инкрементальную загрузку Source -> %s", STAGE_TABLE)

    last_insert_dt = get_last_insert_dt()

    loaded_rows = copy_rows_between_databases(
        select_sql="""
            select
                  id
                , "desc"
                , create_date
                , plan_date
                , "location"
                , place
                , author_id
                , author_nm
                , author_position
                , responsible_id
                , responsible_nm
                , responsible_position
                , status
                , close_date
                , estimated_value
                , critical
                , photo
                , escalated
                , insert_dt
            from source_data.source_table
            where (%(last_insert_dt)s is null or insert_dt > %(last_insert_dt)s)
            order by insert_dt, id;
        """,
        select_params={"last_insert_dt": last_insert_dt},
        target_table=STAGE_TABLE,
    )

    logger.info(
        "Инкрементальная загрузка завершена. Граница: %s. Загружено строк: %s",
        last_insert_dt,
        loaded_rows,
    )
