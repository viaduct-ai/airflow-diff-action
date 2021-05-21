#!/bin/bash -l

export HOME=/home/airflow
export PATH="$HOME/.local/bin:$PATH"
export AIRFLOW__CORE__DAGS_FOLDER=${GITHUB_WORKSPACE}/
export AIRFLOW__CORE__PLUGINS_FOLDER=${GITHUB_WORKSPACE}/plugins/
export AIRFLOW__CORE__LOGS_FOLDER="/tmp/logs/"
export FERNET_KEY=$(openssl rand -base64 32)
echo Base ref is $GITHUB_BASE_REF
airflow initdb
python /dump_dags.py /tmp/current.txt
git checkout $GITHUB_BASE_REF
python /dump_dags.py /tmp/base.txt
diff=$(diff -u /tmp/base.txt /tmp/current.txt)
exit 0
