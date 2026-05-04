#!/bin/bash
set -e

HERMES_UID="${HERMES_UID:-10000}"
HERMES_GID="${HERMES_GID:-10000}"

# Railway volumes mount as root-owned. Upstream's entrypoint chowns
# /opt/data but doesn't know about our HERMES_HOME=/data/hermes, so we
# create and hand off /data/hermes before the upstream script drops
# privileges.
mkdir -p /data/hermes
chown "$HERMES_UID:$HERMES_GID" /data /data/hermes

exec /opt/hermes/docker/entrypoint.sh "$@"
