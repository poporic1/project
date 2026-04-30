from __future__ import annotations

import logging
import re
from decimal import Decimal

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from airflow.exceptions import AirflowFailException
from airflow.providers.postgres.hooks.postgres import PostgresHook


logger = logging.getLogger(__name__)

DWH_CONN_ID = "dwh_db"
CBR_URL = "https://www.cbr-xml-daily.com/daily_json.js"

HTTP_TIMEOUT = 30
HTTP_RETRIES = 3
HTTP_BACKOFF_FACTOR = 0.5
HTTP_STATUS_FORCELIST = (500, 502, 503, 504)

# по спецификации в текстовых полях разрешены только буквы, цифры, пробел, точка, запятая и дефис
ALLOWED_TEXT_PATTERN = re.compile(r"^[0-9A-Za-zА-Яа-яЁё .,\-]+$")

UPSERT_CURRENCY_SQL = """
    insert into dds.dim_currency (
        curr_code,
        curr_name,
        curr_value,
        curr_nominal,
        updated_at
    )
    values (%s, %s, %s, %s, %s::timestamptz)
    on conflict (curr_code) do update
    set curr_name = excluded.curr_name,
        curr_value = excluded.curr_value,
        curr_nominal = excluded.curr_nominal,
        updated_at = excluded.updated_at;
"""


def create_cbr_session() -> requests.Session:
    """
    Создает HTTP-сессию для запроса к API ЦБ РФ.

    :return: HTTP-сессия с настроенными повторами для временных ошибок.
    :rtype: requests.Session
    """
    session = requests.Session()
    retry_strategy = Retry(
        total=HTTP_RETRIES,
        backoff_factor=HTTP_BACKOFF_FACTOR,
        status_forcelist=HTTP_STATUS_FORCELIST,
        allowed_methods=("GET",),
    )

    session.mount("https://", HTTPAdapter(max_retries=retry_strategy))
    return session


def validate_text_value(value: str) -> bool:
    """
    Проверяет текстовое значение по набору допустимых символов.

    :param value: Проверяемое текстовое значение.
    :type value: str
    :return: True, если значение соответствует требованиям.
    :rtype: bool
    """
    return bool(value and ALLOWED_TEXT_PATTERN.fullmatch(value))


def fetch_currency_json() -> dict:
    """
    Получает JSON с актуальными курсами валют из API ЦБ РФ.

    :return: Ответ API в виде словаря.
    :rtype: dict
    :raises AirflowFailException: Если API вернул некорректный ответ.
    :raises requests.RequestException: Если запрос завершился сетевой ошибкой.
    """
    session = create_cbr_session()
    logger.info("Запрашиваю курсы валют из API ЦБ РФ: %s", CBR_URL)

    try:
        response = session.get(CBR_URL, timeout=HTTP_TIMEOUT)
        response.raise_for_status()
    except requests.HTTPError as error:
        status_code = error.response.status_code if error.response is not None else None
        logger.exception("HTTP-ошибка при запросе API ЦБ РФ")

        if status_code is not None and 400 <= status_code < 500:
            raise AirflowFailException(
                f"Клиентская ошибка API ЦБ РФ: {status_code}"
            ) from error

        raise
    except requests.RequestException:
        logger.exception("Сетевая ошибка при запросе API ЦБ РФ")
        raise

    try:
        data = response.json()
    except ValueError as error:
        raise AirflowFailException("Ответ API ЦБ РФ не является корректным JSON") from error

    if not data.get("Valute"):
        raise AirflowFailException("В ответе API ЦБ РФ отсутствует блок Valute")

    if not data.get("Date"):
        raise AirflowFailException("В ответе API ЦБ РФ отсутствует поле Date")

    return data


def build_currency_records(data: dict) -> list[tuple[str, str, Decimal, int, str]]:
    """
    Преобразует JSON API ЦБ РФ в записи для dds.dim_currency.

    :param data: Ответ API ЦБ РФ.
    :type data: dict
    :return: Список записей для вставки или обновления.
    :rtype: list[tuple[str, str, Decimal, int, str]]
    :raises AirflowFailException: Если не удалось подготовить ни одной записи.
    """
    records = []
    skipped = 0
    updated_at = data["Date"]

    for char_code, info in data["Valute"].items():
        try:
            curr_code = str(info["CharCode"]).strip()
            curr_name = str(info["Name"]).strip()
            curr_value = Decimal(str(info["Value"]))
            curr_nominal = int(info["Nominal"])

            if not validate_text_value(curr_code):
                skipped += 1
                logger.warning(
                    "Пропущена валюта %s: код содержит недопустимые символы",
                    char_code,
                )
                continue

            if not validate_text_value(curr_name):
                skipped += 1
                logger.warning(
                    "Пропущена валюта %s: название содержит недопустимые символы",
                    char_code,
                )
                continue

            records.append((
                curr_code,
                curr_name,
                curr_value,
                curr_nominal,
                updated_at,
            ))
        except (KeyError, ValueError, TypeError, ArithmeticError) as error:
            skipped += 1
            logger.warning("Пропущена валюта %s: %s", char_code, error)

    if not records:
        raise AirflowFailException("Нет корректных записей валют для загрузки")

    logger.info("Подготовлено валют: %s, пропущено: %s", len(records), skipped)
    return records


def upsert_currency_records(records: list[tuple[str, str, Decimal, int, str]]) -> None:
    """
    Обновляет dds.dim_currency подготовленными курсами валют.

    :param records: Записи для вставки или обновления.
    :type records: list[tuple[str, str, Decimal, int, str]]
    :return: None
    :rtype: None
    :raises Exception: Если обновление dds.dim_currency завершилось ошибкой.
    """
    conn = PostgresHook(postgres_conn_id=DWH_CONN_ID).get_conn()

    try:
        with conn.cursor() as cursor:
            cursor.executemany(UPSERT_CURRENCY_SQL, records)

        conn.commit()
        logger.info("Справочник dds.dim_currency обновлен. Записей: %s", len(records))
    except Exception:
        conn.rollback()
        logger.exception("Ошибка при обновлении dds.dim_currency")
        raise
    finally:
        conn.close()


def refresh_dim_currency() -> None:
    """
    Загружает актуальные курсы валют из API ЦБ РФ в dds.dim_currency.

    :return: None
    :rtype: None
    """
    data = fetch_currency_json()
    records = build_currency_records(data)
    upsert_currency_records(records)
