FROM apache/airflow:1.10.10-python3.7

# Note: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#docker-container-filesystem
# "GitHub Actions must be run by the default Docker user (root)."

USER root

RUN apt-get update && apt-get install -y git graphviz

COPY entrypoint.sh /entrypoint.sh
COPY dump_dags.py /dump_dags.py

ENTRYPOINT ["/entrypoint.sh"]
