#!/bin/bash
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

# Restart a single process in place if it dies. After too many crashes
# in a short window we give up so Railway can restart the whole
# container — that handles the case where the upstream image itself
# is wedged in a way an in-process restart won't recover from.
MAX_CRASHES_PER_WINDOW=5
WINDOW_SECONDS=60

supervise() {
	local name="$1"
	shift
	local count=0
	local window_start=0

	while true; do
		echo "[supervisor] [$name] starting: $*" >&2
		"$@"
		local code=$?
		local now
		now=$(date +%s)

		if (( now - window_start > WINDOW_SECONDS )); then
			window_start=$now
			count=1
		else
			count=$((count + 1))
		fi

		echo "[supervisor] [$name] exited with $code (crash $count of $MAX_CRASHES_PER_WINDOW in ${WINDOW_SECONDS}s window)" >&2

		if (( count >= MAX_CRASHES_PER_WINDOW )); then
			echo "[supervisor] [$name] giving up — container will exit so Railway restarts the deploy" >&2
			return "$code"
		fi

		sleep 2
	done
}

supervise gateway   hermes gateway run &
supervise dashboard hermes dashboard --port 9119 &

# Give gateway+dashboard a head start before Caddy starts proxying.
sleep 3

supervise caddy caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &

# Block until any supervisor itself bails (i.e. its child exceeded the
# crash limit). If that happens, exit non-zero so Railway's
# restartPolicy reboots the container.
wait -n
EXIT=$?
echo "[supervisor] a supervised process gave up (exit=$EXIT) — terminating container" >&2
[ "$EXIT" -eq 0 ] && EXIT=1
exit "$EXIT"
