import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from etl.stage_loader import load_incremental_new_data_to_stage_table


# DAG инкрементальной загрузки Source в Stage
with DAG(
    dag_id="source_to_stage_incremental_load",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    schedule="0 7 * * *",
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # инкрементальная загрузка новых строк из Source в stage.source_table
    load_incremental_new_data_to_stage_table_task = PythonOperator(
        task_id="load_incremental_new_data_to_stage_table",
        python_callable=load_incremental_new_data_to_stage_table,
    )

    finish = EmptyOperator(task_id="finish")

    (
        start
        >> load_incremental_new_data_to_stage_table_task
        >> finish
    )
