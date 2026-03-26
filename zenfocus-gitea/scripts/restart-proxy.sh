#!/usr/bin/env bash
set -euo pipefail

# restart-proxy.sh
# Restart the proxy service defined in the project's Docker Compose file.
#
# Usage:
#   ./scripts/restart-proxy.sh [service]
# Example: ./scripts/restart-proxy.sh proxy
# If no service is provided, the default is "proxy".

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVICE="${1:-proxy}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose}"

usage(){
  cat <<EOF
Usage: $0 [service]
Default service: proxy
Environment:
  COMPOSE_CMD   docker-compose command (default: 'docker compose')

Examples:
  $0           # restart 'proxy' via docker compose
  $0 nginx     # restart the 'nginx' service defined in the compose file
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

echo "Restarting service '${SERVICE}' in project: ${PROJECT_ROOT}"
cd "$PROJECT_ROOT"

# Try restarting via docker compose
if $COMPOSE_CMD restart "$SERVICE" >/dev/null 2>&1; then
  echo "Proxy restarted successfully via '$COMPOSE_CMD restart $SERVICE'."
  exit 0
fi

# Fallback: try restarting the container directly (useful if a container name was provided)
echo "Failed to restart with '$COMPOSE_CMD'. Trying 'docker restart ${SERVICE}'..."
if docker restart "$SERVICE" >/dev/null 2>&1; then
  echo "Container '${SERVICE}' restarted successfully via 'docker restart'."
  exit 0
fi

echo "Unable to restart the proxy. Check the service/container name and Docker status." >&2
exit 2
