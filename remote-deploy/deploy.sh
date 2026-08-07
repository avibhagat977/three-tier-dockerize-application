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
# Login ECR
# ------------------------------------
echo "Logging into Amazon ECR..."
eval "${ECR_LOGIN_COMMAND}"

# ------------------------------------
# First deployment detection
# ------------------------------------
if [ -z "$(docker compose -f docker-compose.yml --env-file .env ps -q)" ]; then
    echo "======================================"
    echo "First deployment detected."
    echo "Bootstrapping complete application..."
    echo "======================================"

    docker compose -f docker-compose.yml --env-file .env pull
    docker compose -f docker-compose.yml --env-file .env up -d

    echo "Application bootstrapped successfully."
    exit 0
fi

# ------------------------------------
# Rolling deployment
# ------------------------------------
echo "Updating application..."

docker compose -f docker-compose.yml --env-file .env down
docker compose -f docker-compose.yml --env-file .env pull
docker compose -f docker-compose.yml --env-file .env up -d

echo "Deployment completed successfully."



# ------------------------------------
# Cleanup old images
# ------------------------------------
docker image prune -a --filter "label=app=$SERVICE_NAME" --filter "label=service=$SERVICE_NAME"  --force


# ------------------------------------
# Logs
# ------------------------------------
# docker compose -f docker-compose-ingestion.yml --env-file .env-ingestion logs -f ingestion-service
