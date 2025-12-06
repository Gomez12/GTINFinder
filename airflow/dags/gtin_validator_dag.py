"""
GTIN Validator DAG
This DAG validates GTIN codes and prepares them for processing
"""

from __future__ import annotations

import pendulum
from datetime import datetime, timedelta

from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import logging

logger = logging.getLogger(__name__)

def validate_gtin_format(gtin: str) -> bool:
    """
    Validate GTIN format (8, 12, 13, or 14 digits)
    """
    # Remove any non-digit characters
    clean_gtin = ''.join(filter(str.isdigit, gtin))
    
    # Check length
    if len(clean_gtin) not in [8, 12, 13, 14]:
        return False
    
    # Calculate checksum
    return calculate_checksum(clean_gtin) == int(clean_gtin[-1])

def calculate_checksum(gtin: str) -> int:
    """
    Calculate GTIN checksum
    """
    digits = [int(d) for d in gtin[:-1]]
    
    # Multipliers depend on GTIN length
    if len(gtin) == 8:
        multipliers = [3, 1, 3, 1, 3, 1, 3]
    elif len(gtin) == 12:
        multipliers = [1, 3] * 6
    elif len(gtin) == 13:
        multipliers = [1, 3] * 6 + [1]
    else:  # 14
        multipliers = [3, 1] * 7
    
    # Calculate sum
    total = sum(digit * multiplier for digit, multiplier in zip(digits, multipliers))
    
    # Calculate checksum
    return (10 - (total % 10)) % 10

def check_duplicates(**context) -> None:
    """
    Check for duplicate GTIN codes
    """
    postgres_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Find duplicates
    sql = """
    SELECT gtin_code, COUNT(*) as count
    FROM gtins
    WHERE status = 'pending'
    GROUP BY gtin_code
    HAVING COUNT(*) > 1
    """
    
    duplicates = postgres_hook.get_records(sql)
    
    if duplicates:
        logger.warning(f"Found {len(duplicates)} duplicate GTIN codes:")
        for gtin_code, count in duplicates:
            logger.warning(f"  {gtin_code}: {count} occurrences")
        
        # Mark duplicates as duplicate
        for gtin_code, _ in duplicates:
            update_sql = """
            UPDATE gtins 
            SET status = 'duplicate', updated_at = NOW()
            WHERE gtin_code = %s AND status = 'pending'
            """
            postgres_hook.run(update_sql, parameters=(gtin_code,))
    else:
        logger.info("No duplicate GTIN codes found")

def validate_pending_gtins(**context) -> None:
    """
    Validate all pending GTIN codes
    """
    postgres_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # Get all pending GTINs
    sql = """
    SELECT id, gtin_code 
    FROM gtins 
    WHERE status = 'pending'
    """
    
    pending_gtins = postgres_hook.get_records(sql)
    logger.info(f"Found {len(pending_gtins)} pending GTIN codes to validate")
    
    valid_count = 0
    invalid_count = 0
    
    for gtin_id, gtin_code in pending_gtins:
        if validate_gtin_format(gtin_code):
            valid_count += 1
            # Mark as valid
            update_sql = """
            UPDATE gtins 
            SET status = 'valid', updated_at = NOW()
            WHERE id = %s
            """
            postgres_hook.run(update_sql, parameters=(gtin_id,))
        else:
            invalid_count += 1
            # Mark as invalid
            update_sql = """
            UPDATE gtins 
            SET status = 'invalid', updated_at = NOW()
            WHERE id = %s
            """
            postgres_hook.run(update_sql, parameters=(gtin_id,))
    
    logger.info(f"Validation complete: {valid_count} valid, {invalid_count} invalid")

with DAG(
    dag_id='gtin_validator_dag',
    default_args={
        'owner': 'gtin-finder',
        'depends_on_past': False,
        'start_date': pendulum.datetime(2024, 1, 1, tz="UTC"),
        'email_on_failure': False,
        'email_on_retry': False,
        'retries': 1,
        'retry_delay': timedelta(minutes=5),
    },
    description='Validate GTIN codes and check for duplicates',
    schedule_interval=timedelta(minutes=5),
    catchup=False,
    tags=['gtin', 'validation'],
) as dag:
    
    # Task to check for duplicates
    check_duplicates_task = PythonOperator(
        task_id='check_duplicates',
        python_callable=check_duplicates,
    )
    
    # Task to validate pending GTINs
    validate_gtins_task = PythonOperator(
        task_id='validate_pending_gtins',
        python_callable=validate_pending_gtins,
    )
    
    # Set task dependencies
    check_duplicates_task >> validate_gtins_task
