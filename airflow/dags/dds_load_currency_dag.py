import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from common.currency_loader import refresh_dim_currency


# DAG ежедневной загрузки курсов валют из API ЦБ РФ в DDS
with DAG(
    dag_id="dds_load_currency",
    schedule="0 8 * * *",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # получение курсов валют из API ЦБ РФ и обновление dds.dim_currency
    refresh_dim_currency_task = PythonOperator(
        task_id="refresh_dim_currency",
        python_callable=refresh_dim_currency,
    )

    finish = EmptyOperator(task_id="finish")

    # порядок выполнения задач
    start >> refresh_dim_currency_task >> finish
