#!/usr/bin/env bash
# Repeatable deployment of a built jar to an environment, with health check and
# automatic rollback.
#
#   usage: deploy/deploy.sh <env> <path-to-jar>
#   e.g.   deploy/deploy.sh test target/contoso-orders-1.0-SNAPSHOT.jar
#
# Layout it creates under $DEPLOY_DIR:
#   releases/<timestamp>/app.jar   every version ever deployed (last 5 kept)
#   current -> releases/<timestamp> the version that is live
#   previous -> releases/<...>      the one before it (rollback target)
#   app.pid, app.log
set -euo pipefail

ENV_NAME="${1:-}"
JAR="${2:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { echo "usage: $0 <env> <path-to-jar>"; exit 2; }
log()   { printf '[deploy %s] %s\n' "$(date +%H:%M:%S)" "$*"; }

[[ -n "$ENV_NAME" && -n "$JAR" ]] || usage
ENV_FILE="$HERE/environments/$ENV_NAME.env"
[[ -f "$ENV_FILE" ]] || { echo "unknown environment '$ENV_NAME' (no $ENV_FILE)"; exit 2; }
[[ -f "$JAR" ]] || { echo "jar not found: $JAR"; exit 2; }

# shellcheck disable=SC1090
source "$ENV_FILE"
export SERVER_PORT SPRING_PROFILES_ACTIVE

RELEASE="$(date +%Y%m%d-%H%M%S)"
RELEASE_DIR="$DEPLOY_DIR/releases/$RELEASE"
PID_FILE="$DEPLOY_DIR/app.pid"
LOG_FILE="$DEPLOY_DIR/app.log"

stop_app() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    local pid; pid="$(cat "$PID_FILE")"
    log "stopping pid $pid"
    kill "$pid"
    for _ in $(seq 1 20); do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
    kill -0 "$pid" 2>/dev/null && { log "still running, killing"; kill -9 "$pid"; }
  fi
  rm -f "$PID_FILE"
}

start_app() {
  local dir="$1"
  log "starting $(basename "$dir") on port $SERVER_PORT"
  # shellcheck disable=SC2086
  nohup java $JAVA_OPTS -jar "$dir/app.jar" >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
}

wait_healthy() {
  local deadline=$((SECONDS + HEALTH_TIMEOUT_SECONDS))
  while (( SECONDS < deadline )); do
    if curl -sf "$HEALTH_URL" 2>/dev/null | grep -q '"UP"'; then return 0; fi
    kill -0 "$(cat "$PID_FILE")" 2>/dev/null || { log "process died"; return 1; }
    sleep 2
  done
  log "no healthy response from $HEALTH_URL within ${HEALTH_TIMEOUT_SECONDS}s"
  return 1
}

rollback() {
  if [[ -n "$OLD_CURRENT" ]]; then
    log "ROLLING BACK to $(basename "$OLD_CURRENT")"
    stop_app
    ln -sfn "$OLD_CURRENT" "$DEPLOY_DIR/current"
    start_app "$OLD_CURRENT"
    if wait_healthy; then log "rollback OK, $(basename "$OLD_CURRENT") is live"; else log "rollback FAILED, manual intervention needed"; fi
  else
    log "nothing to roll back to"
  fi
}

# --- deploy -------------------------------------------------------------------
log "deploying $(basename "$JAR") to '$ENV_NAME' ($DEPLOY_DIR)"
mkdir -p "$RELEASE_DIR"
cp "$JAR" "$RELEASE_DIR/app.jar"
sha256sum "$RELEASE_DIR/app.jar" | awk '{print $1}' >"$RELEASE_DIR/app.jar.sha256"

OLD_CURRENT=""
[[ -L "$DEPLOY_DIR/current" ]] && OLD_CURRENT="$(readlink -f "$DEPLOY_DIR/current")"

stop_app
ln -sfn "$RELEASE_DIR" "$DEPLOY_DIR/current"
start_app "$RELEASE_DIR"

if wait_healthy; then
  log "SUCCESS: release $RELEASE is live at $HEALTH_URL"
  # only now does the old release become the rollback target
  [[ -n "$OLD_CURRENT" ]] && ln -sfn "$OLD_CURRENT" "$DEPLOY_DIR/previous"
  # keep the last 5 releases
  ls -1dt "$DEPLOY_DIR"/releases/* | tail -n +6 | xargs -r rm -rf
  exit 0
else
  log "FAILED: release $RELEASE did not become healthy (see $LOG_FILE)"
  rollback
  rm -rf "$RELEASE_DIR"
  exit 1
fi
