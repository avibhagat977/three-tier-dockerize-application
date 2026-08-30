#!/bin/bash

URL="https://todo.thegenesys.tech/api/tasks?project_id=1"
INTERVAL=2

# ------------------------------------------------------------
# Counters
# ------------------------------------------------------------

UP_COUNT=0
DOWN_COUNT=0

# ------------------------------------------------------------
# Total completed time spent in each state
# ------------------------------------------------------------

TOTAL_UPTIME=0
TOTAL_DOWNTIME=0

# ------------------------------------------------------------
# Current state
# ------------------------------------------------------------

CURRENT_STATE="UNKNOWN"
STATE_START=$(date +%s)

while true; do

    # --------------------------------------------------------
    # Current timestamp
    # --------------------------------------------------------

    NOW=$(date +%s)
    DISPLAY_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    echo "============================================================"
    echo "Time: $DISPLAY_TIME"

    # --------------------------------------------------------
    # Call API
    #
    # -s              = silent curl output
    # --max-time 10   = timeout after 10 seconds
    # -w              = append HTTP status code
    # --------------------------------------------------------

    RESPONSE=$(curl -s \
        --max-time 10 \
        -w "\n%{http_code}" \
        "$URL")

    # --------------------------------------------------------
    # Extract HTTP status code
    # --------------------------------------------------------

    STATUS=$(echo "$RESPONSE" | tail -n 1)

    # --------------------------------------------------------
    # Extract response body
    # Everything except the final HTTP status line
    # --------------------------------------------------------

    BODY=$(echo "$RESPONSE" | sed '$d')

    # --------------------------------------------------------
    # Determine whether the service is UP or DOWN
    #
    # Only HTTP 200 is considered UP.
    # Everything else is considered DOWN.
    # --------------------------------------------------------

    if [ "$STATUS" = "200" ]; then
        STATE="UP"
    else
        STATE="DOWN"
    fi

    # --------------------------------------------------------
    # Handle the first check
    #
    # We don't have a previous state yet.
    # Start timing the current state.
    # --------------------------------------------------------

    if [ "$CURRENT_STATE" = "UNKNOWN" ]; then

        CURRENT_STATE="$STATE"
        STATE_START="$NOW"

    # --------------------------------------------------------
    # Handle a state change
    #
    # Example:
    #
    # UP → DOWN
    # DOWN → UP
    #
    # When the state changes, calculate how long the previous
    # state lasted and add it to the appropriate total.
    # --------------------------------------------------------

    elif [ "$STATE" != "$CURRENT_STATE" ]; then

        STATE_DURATION=$((NOW - STATE_START))

        if [ "$CURRENT_STATE" = "UP" ]; then
            TOTAL_UPTIME=$((TOTAL_UPTIME + STATE_DURATION))
        else
            TOTAL_DOWNTIME=$((TOTAL_DOWNTIME + STATE_DURATION))
        fi

        # Start timing the new state
        CURRENT_STATE="$STATE"
        STATE_START="$NOW"

    fi

    # --------------------------------------------------------
    # Count checks
    # --------------------------------------------------------

    if [ "$STATE" = "UP" ]; then
        UP_COUNT=$((UP_COUNT + 1))
    else
        DOWN_COUNT=$((DOWN_COUNT + 1))
    fi

    # --------------------------------------------------------
    # Calculate how long the CURRENT state has lasted
    # --------------------------------------------------------

    CURRENT_STATE_DURATION=$((NOW - STATE_START))

    # --------------------------------------------------------
    # IMPORTANT:
    #
    # Include the CURRENT state duration when calculating
    # total uptime/downtime.
    #
    # This fixes the previous problem where:
    #
    # Current state duration = 9s
    # Total uptime          = 0s
    #
    # --------------------------------------------------------

    if [ "$CURRENT_STATE" = "UP" ]; then

        CURRENT_TOTAL_UPTIME=$((TOTAL_UPTIME + CURRENT_STATE_DURATION))
        CURRENT_TOTAL_DOWNTIME=$TOTAL_DOWNTIME

    else

        CURRENT_TOTAL_UPTIME=$TOTAL_UPTIME
        CURRENT_TOTAL_DOWNTIME=$((TOTAL_DOWNTIME + CURRENT_STATE_DURATION))

    fi

    # --------------------------------------------------------
    # Calculate total monitored time
    # --------------------------------------------------------

    TOTAL_TIME=$((CURRENT_TOTAL_UPTIME + CURRENT_TOTAL_DOWNTIME))

    # --------------------------------------------------------
    # Calculate availability
    # --------------------------------------------------------

    if [ "$TOTAL_TIME" -gt 0 ]; then

        AVAILABILITY=$(awk \
            "BEGIN {printf \"%.2f\", ($CURRENT_TOTAL_UPTIME / $TOTAL_TIME) * 100}")

    else

        AVAILABILITY="100.00"

    fi

    # --------------------------------------------------------
    # Display HTTP information
    # --------------------------------------------------------

    echo "HTTP Status: $STATUS"
    echo "Status:      $STATE"

    echo
    echo "Response:"

    # --------------------------------------------------------
    # Check whether the response is valid JSON
    #
    # If JSON:
    #     show task ID 6
    #
    # If not JSON:
    #     show the raw response
    #
    # This is useful for seeing errors such as:
    #
    # 502
    # 503
    # connection refused
    # upstream errors
    # --------------------------------------------------------

    if echo "$BODY" | jq empty 2>/dev/null; then

        echo "$BODY" | jq '.tasks[] | select(.id == 6)'

    else

        echo "$BODY"

    fi

    echo
    echo "-------------------- Statistics ----------------------------"

    echo "UP checks:              $UP_COUNT"
    echo "DOWN checks:            $DOWN_COUNT"

    echo "Current state:          $CURRENT_STATE"
    echo "Current state duration: ${CURRENT_STATE_DURATION}s"

    echo
    echo "Total uptime:           ${CURRENT_TOTAL_UPTIME}s"
    echo "Total downtime:         ${CURRENT_TOTAL_DOWNTIME}s"

    echo "Availability:           ${AVAILABILITY}%"

    echo "============================================================"
    echo "Next check in ${INTERVAL} seconds..."
    echo

    sleep "$INTERVAL"

done