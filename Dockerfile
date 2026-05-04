FROM nousresearch/hermes-agent:latest

ENV HERMES_HOME=/data \
    GATEWAY_HEALTH_URL=http://localhost:8642

EXPOSE 9119

CMD ["sh", "-c", "hermes gateway run & sleep 3 && exec hermes dashboard --host 0.0.0.0 --insecure"]
