#!/bin/bash -l

export HOME=/home/airflow
export PATH="$HOME/.local/bin:$PATH"
export AIRFLOW__CORE__DAGS_FOLDER=${GITHUB_WORKSPACE}/
export AIRFLOW__CORE__PLUGINS_FOLDER=${GITHUB_WORKSPACE}/plugins/
export AIRFLOW__CORE__LOGS_FOLDER="/tmp/logs/"
export FERNET_KEY=$(openssl rand -base64 32)
export REQUIREMENTS_FILE=${GITHUB_WORKSPACE}/requirements.txt
sudo pip install -r ${REQUIREMENTS_FILE}
RUN_ID=$(uuidgen)
RESULTS_DIR=${GITHUB_WORKSPACE}/airflow-diff-results
git config --global --add safe.directory $GITHUB_WORKSPACE
mkdir -p $RESULTS_DIR
echo Base ref is $GITHUB_BASE_REF, head ref is $GITHUB_HEAD_REF
airflow db init 
if ! python /dump_dags.py /tmp/current ; then
    echo "::set-output name=diff::ERROR: Failed to parse DAGs."
    exit 0 # Avoid failing the script so the PR comment can be posted.
fi
git checkout $GITHUB_BASE_REF
if ! python /dump_dags.py /tmp/base ; then
    echo "::set-output name=diff::ERROR: Failed to parse base DAGs."
    exit 0 # Avoid failing the script so the PR comment can be posted.
fi
git checkout $GITHUB_HEAD_REF # Revert to head for printing dag below
DAG_IDS=$(basename -a /tmp/base/* /tmp/current/* | sort | uniq)
SUMMARY=""
for dag_id in $DAG_IDS; do
    DIFF=''
    if [[ ! -f "/tmp/current/$dag_id" ]]; then
        SUMMARY+="**DAG deleted: $dag_id**"$'\n\n'
    elif [[ ! -f "/tmp/base/$dag_id" ]]; then
        DIFF=$(< /tmp/current/$dag_id)
        if [ -n "$DIFF" ]; then
            SUMMARY+="**DAG added: $dag_id**"
        fi
    else
        DIFF=$(diff -u /tmp/base/$dag_id /tmp/current/$dag_id)
        if [ -n "$DIFF" ]; then
            # Strip first 2 lines with the filenames.
            DIFF=$(echo "$DIFF" | tail -n +3)
            SUMMARY+="**DAG modified: $dag_id**"
        fi
    fi
    if [ -n "$DIFF" ]; then
        echo "$DIFF" > $RESULTS_DIR/$dag_id.txt
        airflow show_dag -s $RESULTS_DIR/$dag_id.png $dag_id
        if [ -n "$S3_PROXY_URL" ]; then
            SUMMARY+=" ([diff]($S3_PROXY_URL/$S3_BASE_DIR/$RUN_ID/$dag_id.txt)) ([image]($S3_PROXY_URL/$S3_BASE_DIR/$RUN_ID/$dag_id.png))"
        fi
        if [ $(echo "$DIFF" | wc -l) -gt 100 ]; then
            DIFF="Large diff omitted"
        fi
        SUMMARY+=$'\n\n```\n'"$DIFF"$'\n```\n\n'
    fi
done
if [ -z "$SUMMARY" ]; then
    SUMMARY='No diff in DAG structure'
fi
if [ -n "$S3_PROXY_URL" ] && [ "$(ls $RESULTS_DIR)" ]; then
    aws s3 cp $RESULTS_DIR "s3://$S3_BUCKET/$S3_BASE_DIR/$RUN_ID" --recursive
fi
SUMMARY="${SUMMARY//'%'/'%25'}"
SUMMARY="${SUMMARY//$'\n'/'%0A'}"
SUMMARY="${SUMMARY//$'\r'/'%0D'}"
echo "::set-output name=diff::$SUMMARY"
exit 0
