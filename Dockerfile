FROM nousresearch/hermes-agent:v2026.4.30

USER root

ARG CADDY_VERSION=2.11.2
RUN curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" \
      | tar -xz -C /usr/local/bin caddy \
 && chmod +x /usr/local/bin/caddy

RUN apt-get update \
 && apt-get install -y --no-install-recommends vim \
 && rm -rf /var/lib/apt/lists/* \
 && echo 'inoremap jj <Esc>' >> /etc/vim/vimrc

RUN [ -x /opt/hermes/.venv/bin/hermes ] && ln -sf /opt/hermes/.venv/bin/hermes /usr/local/bin/hermes

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /opt/hermes-railway/entrypoint.sh
COPY init.sh /opt/hermes-railway/init.sh
RUN chmod +x /opt/hermes-railway/entrypoint.sh /opt/hermes-railway/init.sh

ENV HERMES_HOME=/data/hermes \
    HOME=/data/hermes \
    GATEWAY_HEALTH_URL=http://localhost:8642 \
    PORT=8080

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/hermes-railway/init.sh"]
CMD ["/opt/hermes-railway/entrypoint.sh"]
