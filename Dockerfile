FROM apache/airflow:1.10.10-python3.7

COPY entrypoint.sh /entrypoint.sh
COPY dump_dags.py /dump_dags.py

ENTRYPOINT ["/entrypoint.sh"]
