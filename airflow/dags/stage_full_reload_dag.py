import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

from etl.dwh import execute_dwh_sql
from etl.stage_loader import load_all_source_data_to_tmp_table


# DAG полной перегрузки данных между Source и Stage через tmp-таблицу
with DAG(
    dag_id="source_to_stage_full_reload",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # загрузка полного набора данных из Source во временную таблицу
    load_all_source_data_to_tmp_table_task = PythonOperator(
        task_id="load_all_source_data_to_tmp_table",
        python_callable=load_all_source_data_to_tmp_table,
    )

    # свап между временной таблицей с новыми данными и нашей целевой таблицей
    replace_table_with_tmp_task = PythonOperator(
        task_id="replace_table_with_tmp",
        python_callable=execute_dwh_sql,
        op_args=[
            """
            call public.replace_table_with_tmp(
              'stage',
              'source_table',
              'tmp_source_table'
            );
            """
        ],
    )

    finish = EmptyOperator(task_id="finish")

    (
        start
        >> load_all_source_data_to_tmp_table_task
        >> replace_table_with_tmp_task
        >> finish
    )
