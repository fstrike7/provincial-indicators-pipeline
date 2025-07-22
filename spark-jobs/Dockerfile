FROM eclipse-temurin:21-jdk AS base

# Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv ca-certificates curl && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# dependencies
COPY requirements.txt .
# venv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt


COPY jobs /opt/jobs
COPY run.sh /opt/run.sh
RUN chmod +x /opt/run.sh /opt/jobs/aggregate_indicators.py

ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/opt/run.sh"]