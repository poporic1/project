import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup

from etl.dwh import execute_dwh_sql


# DAG загрузки данных из DDS в DM
with DAG(
    dag_id="dds_to_dm_load",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    schedule="0 9 * * *",
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # общая группа загрузки DM-слоя
    with TaskGroup(group_id="load_dm") as load_dm_group:

        # загрузка справочника мест и локаций
        load_dim_place_location_task = PythonOperator(
            task_id="load_dim_place_location",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_dim_place_location();"],
        )

        # загрузка справочника статусов
        load_dim_status_task = PythonOperator(
            task_id="load_dim_status",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_dim_status();"],
        )

        # загрузка справочника ответственных
        load_dim_responsible_task = PythonOperator(
            task_id="load_dim_responsible",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_dim_responsible();"],
        )

        # загрузка справочника месяцев
        load_dim_month_task = PythonOperator(
            task_id="load_dim_month",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_dim_month();"],
        )

        # расчет нового набора данных для fact_first_priority в tmp-таблицу
        load_tmp_fact_first_priority_task = PythonOperator(
            task_id="load_tmp_fact_first_priority",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_fact_first_priority();"],
        )

        # новый набор данных fact_first_priority с сохранением предыдущей версии в tmp
        replace_fact_first_priority_with_tmp_task = PythonOperator(
            task_id="replace_fact_first_priority_with_tmp",
            python_callable=execute_dwh_sql,
            op_args=[
                """
                call public.replace_table_with_tmp(
                  'dm',
                  'fact_first_priority',
                  'tmp_fact_first_priority'
                );
                """
            ],
        )

        # расчет нового набора данных для fact_metrics в tmp-таблицу
        load_tmp_fact_metrics_task = PythonOperator(
            task_id="load_tmp_fact_metrics",
            python_callable=execute_dwh_sql,
            op_args=["call dm.load_fact_metrics();"],
        )

        # новый набор данных fact_metrics с сохранением предыдущей версии в tmp
        replace_fact_metrics_with_tmp_task = PythonOperator(
            task_id="replace_fact_metrics_with_tmp",
            python_callable=execute_dwh_sql,
            op_args=[
                """
                call public.replace_table_with_tmp(
                  'dm',
                  'fact_metrics',
                  'tmp_fact_metrics'
                );
                """
            ],
        )

        [load_dim_month_task, load_dim_place_location_task] >> load_tmp_fact_metrics_task
        load_tmp_fact_metrics_task >> replace_fact_metrics_with_tmp_task
        load_tmp_fact_first_priority_task >> replace_fact_first_priority_with_tmp_task

    finish = EmptyOperator(task_id="finish")

    start >> load_dm_group >> finish
