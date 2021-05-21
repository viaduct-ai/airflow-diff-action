#!/bin/bash -l

export HOME=/home/airflow
export PATH="$HOME/.local/bin:$PATH"
export AIRFLOW__CORE__DAGS_FOLDER=${GITHUB_WORKSPACE}/
export AIRFLOW__CORE__PLUGINS_FOLDER=${GITHUB_WORKSPACE}/plugins/
export AIRFLOW__CORE__LOGS_FOLDER="/tmp/logs/"
export FERNET_KEY=$(openssl rand -base64 32)
RESULTS_DIR=${GITHUB_WORKSPACE}/airflow-diff-results
mkdir -p $RESULTS_DIR
echo Base ref is $GITHUB_BASE_REF
airflow initdb
python /dump_dags.py /tmp/current
git checkout $GITHUB_BASE_REF
python /dump_dags.py /tmp/base
DAG_IDS=$(basename -a /tmp/base/* /tmp/current/* | sort | uniq)
SUMMARY=""
for dag_id in $DAG_IDS; do
    HAS_DIFF=0
    if [[ ! -f "/tmp/current/$dag_id" ]]; then
        SUMMARY+="**DAG deleted: $dag_id**"$'\n\n'
    elif [[ ! -f "/tmp/base/$dag_id" ]]; then
        CONTENT=$(< /tmp/current/$dag_id)
        SUMMARY+="**DAG added: $dag_id**"$'\n\n```\n'"$CONTENT"$'\n```\n\n'
        HAS_DIFF=1
    else
        DIFF=$(diff -u /tmp/base/$dag_id /tmp/current/$dag_id)
        retVal=$?
        if [ $retVal -ne 0 ]; then
            SUMMARY+="**DAG modified: $dag_id**"$'\n\n```\n'"$DIFF"$'\n```\n\n'
            HAS_DIFF=1
        fi
    fi
    if [ $HAS_DIFF -ne 0 ] ; then 
        cp /tmp/current/$dag_id $RESULTS_DIR/$dag_id.txt
        airflow show_dag -s $RESULTS_DIR/$dag_id.png $dag_id
    fi
done
SUMMARY="${SUMMARY//'%'/'%25'}"
SUMMARY="${SUMMARY//$'\n'/'%0A'}"
SUMMARY="${SUMMARY//$'\r'/'%0D'}"
echo "::set-output name=diff::$SUMMARY"
exit 0
