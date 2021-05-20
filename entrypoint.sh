#!/bin/bash -l

export HOME=/home/airflow
export PATH="$HOME/.local/bin:$PATH"
export AIRFLOW__CORE__DAGS_FOLDER=${GITHUB_WORKSPACE}/
export AIRFLOW__CORE__PLUGINS_FOLDER=${GITHUB_WORKSPACE}/plugins/
export AIRFLOW__CORE__LOGS_FOLDER="/tmp/logs/"
export FERNET_KEY=$(openssl rand -base64 32)
cat $GITHUB_EVENT_PATH
airflow initdb
python /main.py
