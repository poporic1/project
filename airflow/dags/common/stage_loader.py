from __future__ import annotations

import csv
import io
import logging
from pathlib import Path
from typing import Any

from airflow.providers.postgres.hooks.postgres import PostgresHook


logger = logging.getLogger(__name__)

DAGS_DIR = Path(__file__).resolve().parents[1]
BATCH_SIZE = 10_000
SOURCE_CONN_ID = "source_db"
DWH_CONN_ID = "dwh_db"
STAGE_TABLE = "stage.source_table"
TMP_STAGE_TABLE = "stage.tmp_source_table"
LAST_INSERT_DT_SQL = f"select max(insert_dt) from {STAGE_TABLE};"

COPY_COLUMNS_SQL = """
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
"""


def read_sql(relative_path: str) -> str:
    """
    Читает SQL-файл из каталога airflow/dags.

    :param relative_path: Относительный путь до SQL-файла.
    :type relative_path: str
    :return: Текст SQL-файла.
    :rtype: str
    """
    file_path = DAGS_DIR / relative_path
    logger.info("Читаю SQL-файл: %s", file_path)
    return file_path.read_text(encoding="utf-8")


def execute_dwh_sql(relative_path: str) -> None:
    """
    Выполняет SQL-файл в DWH.

    :param relative_path: Относительный путь до SQL-файла.
    :type relative_path: str
    :return: None
    :rtype: None
    :raises Exception: Если SQL завершился ошибкой.
    """
    sql = read_sql(relative_path)
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.execute(sql)
        conn.commit()
        logger.info("SQL в DWH успешно выполнен: %s", relative_path)
    except Exception:
        conn.rollback()
        logger.exception("Ошибка при выполнении SQL в DWH: %s", relative_path)
        raise
    finally:
        conn.close()


def get_last_insert_dt() -> str | None:
    """
    Возвращает максимальное значение insert_dt из stage-таблицы.

    :return: Последняя дата загрузки или None, если таблица пустая.
    :rtype: str | None
    """
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.execute(LAST_INSERT_DT_SQL)
            value = cursor.fetchone()[0]
        logger.info("Максимальное значение insert_dt в %s: %s", STAGE_TABLE, value)
        return value
    finally:
        conn.close()


def create_tmp_table() -> None:
    """
    Создает tmp-таблицу для полной перегрузки.

    :return: None
    :rtype: None
    """
    logger.info("Создаю tmp-таблицу для полной перегрузки")
    execute_dwh_sql("dml/stage/create_tmp_table.sql")


def swap_tmp_table_with_stage_table() -> None:
    """
    Подменяет stage-таблицу tmp-таблицей.

    :return: None
    :rtype: None
    """
    logger.info("Начинаю подмену tmp-таблицы и stage-таблицы")
    execute_dwh_sql("dml/stage/swap_tmp_table_with_stage_table.sql")
    logger.info("Подмена tmp-таблицы и stage-таблицы завершена")


def copy_rows_between_databases(
    select_sql: str,
    select_params: dict[str, Any] | None,
    target_table: str,
) -> int:
    """
    Переносит данные из Source PostgreSQL в DWH PostgreSQL батчами.

    :param select_sql: SQL-запрос к source.
    :type select_sql: str
    :param select_params: Параметры SQL-запроса к source.
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
        # Именованный курсор читает результат порциями на стороне Source PostgreSQL.
        source_cursor = source_conn.cursor(name="source_stream_cursor")
        source_cursor.itersize = BATCH_SIZE
        source_cursor.execute(select_sql, select_params)

        with dwh_conn.cursor() as dwh_cursor:
            while True:
                # Берем только следующую порцию строк, а не весь набор сразу.
                rows = source_cursor.fetchmany(BATCH_SIZE)
                if not rows:
                    break

                # Готовим текущий батч как CSV-поток в памяти для COPY FROM STDIN.
                buffer = io.StringIO()
                writer = csv.writer(buffer)
                for row in rows:
                    writer.writerow(["" if value is None else value for value in row])
                buffer.seek(0)

                dwh_cursor.copy_expert(
                    f"""
                    copy {target_table} (
                    {COPY_COLUMNS_SQL}
                    )
                    from stdin with (format csv)
                    """,
                    buffer,
                )
                total_rows += len(rows)
                logger.info("Загружен батч: %s строк. Всего: %s", len(rows), total_rows)

        dwh_conn.commit()
        logger.info(
            "Перенос в таблицу %s завершен. Всего строк: %s", target_table, total_rows
        )
        return total_rows
    except Exception:
        dwh_conn.rollback()
        logger.exception("Ошибка при переносе данных в таблицу %s", target_table)
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
    Загружает все данные из source в tmp-таблицу.

    :return: None
    :rtype: None
    """
    logger.info("Начинаю полную загрузку всех данных из Source в tmp-таблицу")
    loaded_rows = copy_rows_between_databases(
        select_sql=read_sql("dml/stage/load_all_source_data_to_tmp_table.sql"),
        select_params=None,
        target_table=TMP_STAGE_TABLE,
    )
    logger.info(
        "Полная загрузка в tmp-таблицу завершена. Загружено строк: %s", loaded_rows
    )


def load_incremental_new_data_to_stage_table() -> None:
    """
    Дозагружает новые строки из source напрямую в stage-таблицу.

    :return: None
    :rtype: None
    """
    logger.info("Начинаю инкрементальную загрузку новых данных в stage-таблицу")
    last_insert_dt = get_last_insert_dt()
    loaded_rows = copy_rows_between_databases(
        select_sql=read_sql("dml/stage/load_incremental_new_data_to_stage_table.sql"),
        select_params={"last_insert_dt": last_insert_dt},
        target_table=STAGE_TABLE,
    )
    logger.info(
        "Инкрементальная загрузка завершена. Граница: %s. Загружено строк: %s",
        last_insert_dt,
        loaded_rows,
    )
