FROM nousresearch/hermes-agent:v2026.4.30

ENV HERMES_HOME=/data \
    GATEWAY_HEALTH_URL=http://localhost:8642 \
    PORT=8080

EXPOSE 8080

CMD ["sh", "-c", "hermes gateway run & sleep 3 && exec hermes dashboard --host 0.0.0.0 --port ${PORT} --insecure"]
