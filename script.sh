#!/bin/bash

LOG_FILE="/var/ossec/logs/integrations_sms_monitor.log"
ALERTS_JSON="/var/ossec/logs/alerts/alerts.json"

# --- SMS CONFIGURATION ---
RECIPIENTS=("919669288387" "919103283623")
USER="VGVPAY"
PASSWORD="abc123"
SENDER_ID="VGVPAY"
PE_ID="1001297681151040166"
TEMPLATE_ID="1007195263819725513"
ROUTE="07"
CHANNEL="Trans"
DCS="0"
FLASH="0"

# Ensure log file exists
touch "$LOG_FILE"

# Start tailing alerts.json
tail -n0 -F "$ALERTS_JSON" | while read -r line; do
  [[ -z "$line" ]] && continue

  # Extract fields safely using jq
  LEVEL=$(echo "$line" | jq -r '.rule.level // empty')
  HOST=$(echo "$line" | jq -r '.agent.name // empty')
  TIME=$(echo "$line" | jq -r '.timestamp // empty')
  RULE_DESC=$(echo "$line" | jq -r '.rule.description // empty')

  # Debug log
  echo "$(date) | LEVEL=$LEVEL | HOST=$HOST | TIME=$TIME | RULE=$RULE_DESC" >> "$LOG_FILE"

  # Only alert if LEVEL >= 3
  if [[ "$LEVEL" =~ ^[0-9]+$ && "$LEVEL" -ge 3 ]]; then
    SHORT_HOST=$(echo "$HOST" | cut -c1-40)
    SHORT_TIME=$(echo "$TIME" | cut -c1-30)
    VAR_MSG="$LEVEL on $SHORT_HOST at $SHORT_TIME"

    # Ensure DLT length limit safety (typically 50 chars for one var)
    VAR_MSG=$(echo "$VAR_MSG" | cut -c1-50)

    for MOBILE in "${RECIPIENTS[@]}"; do
      echo "$(date) | Sending SMS to $MOBILE | VAR=$VAR_MSG" >> "$LOG_FILE"

      RESPONSE=$(curl -s -G "https://sms.oriantele.in/api/mt/SendSMS" \
        --data-urlencode "user=$USER" \
        --data-urlencode "password=$PASSWORD" \
        --data-urlencode "senderid=$SENDER_ID" \
        --data-urlencode "channel=$CHANNEL" \
        --data-urlencode "DCS=$DCS" \
        --data-urlencode "flashsms=$FLASH" \
        --data-urlencode "number=$MOBILE" \
        --data-urlencode "text=ALERT $VAR_MSG: Unusual system access detected. Immediate review needed. from: CyberSentinel" \
        --data-urlencode "route=$ROUTE" \
        --data-urlencode "Peid=$PE_ID" \
        --data-urlencode "DLTTemplateId=$TEMPLATE_ID")

      echo "$(date) | Sent to $MOBILE | VAR=$VAR_MSG | Response: $RESPONSE" >> "$LOG_FILE"
    done
  fi
done
