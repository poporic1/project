from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from common.stage_loader import (
    create_tmp_table,
    load_all_source_data_to_tmp_table,
    swap_tmp_table_with_stage_table,
)


# DAG полной загрузки Source в Stage через временную таблицу
with DAG(
    dag_id="source_to_stage_full_reload",
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # создание временной таблицы stage.tmp_source_table
    create_tmp_table_task = PythonOperator(
        task_id="create_tmp_table",
        python_callable=create_tmp_table,
    )

    # загрузка всех данных из Source в tmp таблицу
    load_all_source_data_to_tmp_table_task = PythonOperator(
        task_id="load_all_source_data_to_tmp_table",
        python_callable=load_all_source_data_to_tmp_table,
    )

    # подмена tmp таблицы на основную stage.source_table
    swap_tmp_table_with_stage_table_task = PythonOperator(
        task_id="swap_tmp_table_with_stage_table",
        python_callable=swap_tmp_table_with_stage_table,
    )

    finish = EmptyOperator(task_id="finish")

    # порядок выполнения задач
    (
        start
        >> create_tmp_table_task
        >> load_all_source_data_to_tmp_table_task
        >> swap_tmp_table_with_stage_table_task
        >> finish
    )
