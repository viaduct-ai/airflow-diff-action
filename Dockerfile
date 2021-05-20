FROM apache/airflow:1.10.10-python3.7

COPY entrypoint.sh /entrypoint.sh
COPY main.py /main.py

ENTRYPOINT ["/entrypoint.sh"]
