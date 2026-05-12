from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'george',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='garmin_pipeline',
    description='Daily ingestion of Garmin data + dbt transformations',
    default_args=default_args,
    start_date=datetime(2026, 5, 1),
    schedule='0 6 * * *',   # Every day at 06:00 UTC
    catchup=False,
    tags=['garmin', 'dbt', 'analytics'],
) as dag:

    ingest_garmin = BashOperator(
        task_id='ingest_garmin',
        bash_command='cd /opt/airflow && python scripts/ingest_garmin.py',
    )

    dbt_deps = BashOperator(
        task_id='dbt_deps',
        bash_command='cd /opt/airflow/garmin_dbt && dbt deps --profiles-dir /opt/airflow/garmin_dbt',
    )

    dbt_build = BashOperator(
        task_id='dbt_build',
        bash_command='cd /opt/airflow/garmin_dbt && dbt build --profiles-dir /opt/airflow/garmin_dbt',
    )

    ingest_garmin >> dbt_deps >> dbt_build