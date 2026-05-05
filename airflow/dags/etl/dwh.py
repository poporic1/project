from __future__ import annotations

import logging
from typing import Any

from airflow.providers.postgres.hooks.postgres import PostgresHook


logger = logging.getLogger(__name__)

DWH_CONN_ID = "dwh_db"


def execute_dwh_sql(
    sql: str,
    params: tuple[Any, ...] | None = None,
) -> None:
    """
    Выполняет SQL-скрипт в DWH.

    :param sql: SQL-скрипт.
    :type sql: str
    :param params: Параметры SQL-скрипта.
    :type params: tuple[Any, ...] | None
    :return: None
    :rtype: None
    :raises Exception: Если SQL завершился ошибкой.
    """
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)

        conn.commit()
        logger.info(f"SQL скрипт успешно выполнен: {sql}")
    except Exception as e:
        conn.rollback()
        logger.exception(f"Ошибка при выполнении SQL: {e}")
        raise
    finally:
        conn.close()
