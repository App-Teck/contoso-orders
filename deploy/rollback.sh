#!/usr/bin/env bash
# Roll an environment back to the previously deployed release.
#   usage: deploy/rollback.sh <env>
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="${1:-}"; [[ -n "$ENV_NAME" ]] || { echo "usage: $0 <env>"; exit 2; }
# shellcheck disable=SC1090
source "$HERE/environments/$ENV_NAME.env"
[[ -L "$DEPLOY_DIR/previous" ]] || { echo "no previous release recorded in $DEPLOY_DIR"; exit 1; }
exec "$HERE/deploy.sh" "$ENV_NAME" "$(readlink -f "$DEPLOY_DIR/previous")/app.jar"
