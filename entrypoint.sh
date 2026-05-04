#!/bin/sh
set -e

if [ -z "${DASHBOARD_PASSWORD}" ] && [ -z "${DASHBOARD_PASSWORD_HASH}" ]; then
	echo "ERROR: set DASHBOARD_PASSWORD (plaintext) or DASHBOARD_PASSWORD_HASH (bcrypt) in env" >&2
	exit 1
fi

if [ -n "${DASHBOARD_PASSWORD}" ] && [ -z "${DASHBOARD_PASSWORD_HASH}" ]; then
	DASHBOARD_PASSWORD_HASH="$(caddy hash-password --plaintext "${DASHBOARD_PASSWORD}")"
	export DASHBOARD_PASSWORD_HASH
fi

export DASHBOARD_USER="${DASHBOARD_USER:-admin}"

hermes gateway run &
hermes dashboard --port 9119 &

sleep 3

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
