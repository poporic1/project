import pendulum

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup

from etl.dwh import execute_dwh_sql


# DAG загрузки данных из Stage в DDS
with DAG(
    dag_id="stage_to_dds_load",
    start_date=pendulum.datetime(2026, 2, 1, tz="Europe/Moscow"),
    schedule="30 8 * * *",
    catchup=False,
    max_active_runs=1,
) as dag:

    start = EmptyOperator(task_id="start")

    # группа загрузки справочников DDS
    with TaskGroup(group_id="load_dimensions") as load_dimensions_group:

        # загрузка справочника должностей
        load_dim_position_task = PythonOperator(
            task_id="load_dim_position",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_position();"],
        )

        # загрузка справочника сотрудников после загрузки должностей
        load_dim_employee_task = PythonOperator(
            task_id="load_dim_employee",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_employee();"],
        )

        # загрузка справочника локаций
        load_dim_location_task = PythonOperator(
            task_id="load_dim_location",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_location();"],
        )

        # загрузка справочника мест после загрузки локаций
        load_dim_place_task = PythonOperator(
            task_id="load_dim_place",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_place();"],
        )

        # загрузка справочника статусов
        load_dim_status_task = PythonOperator(
            task_id="load_dim_status",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_status();"],
        )

        # загрузка справочника критичности
        load_dim_critical_task = PythonOperator(
            task_id="load_dim_critical",
            python_callable=execute_dwh_sql,
            op_args=["call dds.load_dim_critical();"],
        )

        # порядок загрузки зависимых справочников
        load_dim_position_task >> load_dim_employee_task
        load_dim_location_task >> load_dim_place_task

    # загрузка нового набора данных для dds.fact_request 
    load_fact_request_task = PythonOperator(
        task_id="load_fact_request",
        python_callable=execute_dwh_sql,
        op_args=["call dds.load_fact_request();"],
    )

    finish = EmptyOperator(task_id="finish")

    (
        start
        >> load_dimensions_group
        >> load_fact_request_task
        >> finish
    )
