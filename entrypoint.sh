#!/bin/sh -l

export AIRFLOW_HOME=${GITHUB_WORKSPACE}
export AIRFLOW__CORE__DAGS_FOLDER=${GITHUB_WORKSPACE}/
export AIRFLOW__CORE__PLUGINS_FOLDER=${GITHUB_WORKSPACE}/plugins/
export AIRFLOW__CORE__LOGS_FOLDER="/tmp/logs/"
export FERNET_KEY=$(openssl rand -base64 32)
airflow initdb
python main.py
