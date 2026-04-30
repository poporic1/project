import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from common.stage_loader import load_incremental_new_data_to_stage_table


# DAG инкрементальной загрузки Source в Stage
with DAG(
    dag_id="source_to_stage_incremental_load",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    schedule="0 7 * * *",
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # загрузка только новых данных по insert_dt
    load_incremental_new_data_to_stage_table_task = PythonOperator(
        task_id="load_incremental_new_data_to_stage_table",
        python_callable=load_incremental_new_data_to_stage_table,
    )

    finish = EmptyOperator(task_id="finish")

    # порядок выполнения задач
    start >> load_incremental_new_data_to_stage_table_task >> finish
