"""
Example DAG for GTINFinder
This is a simple DAG to test Airflow setup
"""

from __future__ import annotations

import pendulum
from datetime import datetime, timedelta

from airflow.models.dag import DAG
from airflow.operators.dummy import DummyOperator
from airflow.operators.python import PythonOperator
import logging

logger = logging.getLogger(__name__)

def hello_world():
    """Simple hello world function"""
    logger.info("Hello from GTINFinder Airflow!")
    return "Hello World!"

def check_database_connection():
    """Check database connection"""
    try:
        from airflow.providers.postgres.hooks.postgres import PostgresHook
        postgres_hook = PostgresHook(postgres_conn_id='postgres_default')
        
        # Test connection
        sql = "SELECT 1 as test"
        result = postgres_hook.get_records(sql)
        
        if result and result[0][0] == 1:
            logger.info("Database connection successful!")
            return "Database OK"
        else:
            logger.error("Database connection failed!")
            return "Database Error"
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        return f"Database Error: {e}"

with DAG(
    dag_id='gtin_example_dag',
    default_args={
        'owner': 'gtin-finder',
        'depends_on_past': False,
        'start_date': pendulum.datetime(2024, 1, 1, tz="UTC"),
        'email_on_failure': False,
        'email_on_retry': False,
        'retries': 1,
        'retry_delay': timedelta(minutes=5),
    },
    description='Example DAG for GTINFinder testing',
    schedule_interval=timedelta(hours=1),
    catchup=False,
    tags=['gtin', 'example'],
) as dag:
    
    start = DummyOperator(task_id='start')
    
    hello_task = PythonOperator(
        task_id='hello_world',
        python_callable=hello_world,
    )
    
    db_check_task = PythonOperator(
        task_id='check_database_connection',
        python_callable=check_database_connection,
    )
    
    end = DummyOperator(task_id='end')
    
    start >> hello_task >> db_check_task >> end
