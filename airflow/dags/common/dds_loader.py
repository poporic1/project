from __future__ import annotations

import logging

from airflow.providers.postgres.hooks.postgres import PostgresHook


logger = logging.getLogger(__name__)

DWH_CONN_ID = "dwh_db"


def call_dwh_procedure(procedure_name: str) -> None:
    """
    Выполняет процедуру в DWH.

    :param procedure_name: Полное имя процедуры.
    :type procedure_name: str
    :return: None
    :rtype: None
    :raises Exception: Если процедура завершилась ошибкой.
    """
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.execute(f"call {procedure_name}();")

        conn.commit()
        logger.info("Процедура успешно выполнена: %s", procedure_name)
    except Exception:
        conn.rollback()
        logger.exception("Ошибка при выполнении процедуры: %s", procedure_name)
        raise
    finally:
        conn.close()


def load_dim_position() -> None:
    """
    Загружает справочник должностей.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_position")


def load_dim_location() -> None:
    """
    Загружает справочник локаций.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_location")


def load_dim_status() -> None:
    """
    Загружает справочник статусов.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_status")


def load_dim_critical() -> None:
    """
    Загружает справочник критичности.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_critical")


def load_dim_employee() -> None:
    """
    Загружает справочник сотрудников.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_employee")


def load_dim_place() -> None:
    """
    Загружает справочник мест.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_dim_place")


def load_fact_request() -> None:
    """
    Загружает таблицу фактов по заявкам.

    :return: None
    :rtype: None
    """
    call_dwh_procedure("dds.load_fact_request")
