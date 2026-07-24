#!/bin/bash
set -euo pipefail
SERVICE_NAME="$1"
# ------------------------------------
# Config
# -----------------------------------

FILES=("docker-compose.yml" ".env")
STOP="NO"

# ------------------------------------
# File checks
# ------------------------------------
for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    echo "$FILE exits -> OK."
  else
    STOP="YES"
    echo "$FILE non exits -> NO."
  fi
done

if [[ "$STOP" == "YES" ]]; then
  echo "Alcuni file mancano -> NO."
  exit 1
fi

# ------------------------------------
# Stop Service
# ------------------------------------
docker compose -f docker-compose.yml --env-file .env down "$SERVICE_NAME"

# ------------------------------------
# Login ECR
# ------------------------------------
eval "${ECR_LOGIN_COMMAND}"

# ------------------------------------
# Pull & Start
# ------------------------------------
docker compose -f docker-compose.yml --env-file .env pull "$SERVICE_NAME"
docker compose -f docker-compose.yml --env-file .env up -d "$SERVICE_NAME"


# ------------------------------------
# Cleanup old images
# ------------------------------------
docker image prune -a --filter "label=app=$SERVICE_NAME" --filter "label=service=$SERVICE_NAME"  --force


# ------------------------------------
# Logs
# ------------------------------------
# docker compose -f docker-compose-ingestion.yml --env-file .env-ingestion logs -f ingestion-service
