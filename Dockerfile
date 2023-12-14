ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Note: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#docker-container-filesystem
# "GitHub Actions must be run by the default Docker user (root)."

USER root

RUN apt-get update && apt-get install -y git graphviz curl unzip groff uuid-runtime

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -qu awscliv2.zip && \
	./aws/install --update

COPY entrypoint.sh /entrypoint.sh
COPY dump_dags.py /dump_dags.py

ENTRYPOINT ["/entrypoint.sh"]
