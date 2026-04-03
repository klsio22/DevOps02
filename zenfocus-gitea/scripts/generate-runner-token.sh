#!/usr/bin/env bash
set -euo pipefail

# generate-runner-token.sh
# Generate a Gitea Actions runner registration token from a running Gitea container.
#
# Usage:
#   ./scripts/generate-runner-token.sh [container_name] [app_ini_path]
# Example:
#   ./scripts/generate-runner-token.sh
#   ./scripts/generate-runner-token.sh zenfocus-gitea /data/gitea/conf/app.ini

CONTAINER_NAME="${1:-zenfocus-gitea}"
APP_INI_PATH="${2:-/data/gitea/conf/app.ini}"

usage() {
  cat <<EOF
Usage: $0 [container_name] [app_ini_path]

Arguments:
  container_name   Gitea container name (default: zenfocus-gitea)
  app_ini_path     app.ini path inside container (default: /data/gitea/conf/app.ini)

Examples:
  $0
  $0 zenfocus-gitea /data/gitea/conf/app.ini
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Install/enable Docker and try again." >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "Container '$CONTAINER_NAME' is not running." >&2
  echo "Tip: start the stack first (docker compose up -d)." >&2
  exit 2
fi

echo "Generating runner token from container '$CONTAINER_NAME'..." >&2
TOKEN="$(docker exec -u git "$CONTAINER_NAME" gitea --config "$APP_INI_PATH" actions generate-runner-token)"

if [[ -z "$TOKEN" ]]; then
  echo "Failed to generate token: empty output." >&2
  exit 3
fi

echo "$TOKEN"
echo ""
echo "To use it in .env:" 
echo "ACT_RUNNER_REGISTRATION_TOKEN=$TOKEN"
