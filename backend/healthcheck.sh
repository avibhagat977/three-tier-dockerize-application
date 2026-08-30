#!/bin/sh

# URL="https://todo.thegenesys.tech/api/tasks?project_id=1"
URL="http://localhost:8080/tasks?project_id=1"

# Call the backend running inside this same container.
# -f  = fail on HTTP 4xx/5xx
# -s  = silent
# -S  = still show errors
# --max-time 5 = don't wait longer than 5 seconds
RESPONSE=$(curl -fsS --max-time 5 "$URL") || {
    echo "Health check failed: backend API is unreachable"
    exit 1
}

# Extract the status of task ID 6.
STATUS=$(echo "$RESPONSE" \
    | jq -r '.tasks[] | select(.id == 6) | .status')

# Task 6 must exist and have the expected status.
if [ "$STATUS" = "blocked" ]; then
    echo "Health check passed: task 6 status is blocked"
    exit 0
fi

echo "Health check failed: task 6 status is '$STATUS'"
exit 1