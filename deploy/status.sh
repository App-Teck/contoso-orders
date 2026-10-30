#!/usr/bin/env bash
# Show what is live in an environment.
#   usage: deploy/status.sh <env>
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${1:-}"; [[ -n "$ENV_NAME" ]] || { echo "usage: $0 <env>"; exit 2; }
# shellcheck disable=SC1090
source "$HERE/environments/$ENV_NAME.env"
echo "environment : $ENV_NAME"
echo "current     : $(readlink -f "$DEPLOY_DIR/current" 2>/dev/null | xargs -r basename || echo none)"
echo "previous    : $(readlink -f "$DEPLOY_DIR/previous" 2>/dev/null | xargs -r basename || echo none)"
if [[ -f "$DEPLOY_DIR/app.pid" ]] && kill -0 "$(cat "$DEPLOY_DIR/app.pid")" 2>/dev/null; then
  echo "process     : running (pid $(cat "$DEPLOY_DIR/app.pid"))"
else
  echo "process     : not running"
fi
echo "health      : $(curl -sf "$HEALTH_URL" 2>/dev/null || echo unreachable)"
