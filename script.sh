#!/bin/bash

LOG_FILE="/var/ossec/logs/integrations_sms_monitor.log"
ALERTS_JSON="/var/ossec/logs/alerts/alerts.json"

# --- OpenSearch Dynamic Recipient Fetch ---
OPENSEARCH_HOST="http://192.168.1.12:9200"
OPENSEARCH_INDEX="users"
ROLE_FILTER="administrator"

# Ensure log file exists
touch "$LOG_FILE"

# Fetch phone numbers from OpenSearch
RESPONSE=$(curl -s -X POST "$OPENSEARCH_HOST/$OPENSEARCH_INDEX/_search" \
  -H 'Content-Type: application/json' -d "
{
  \"_source\": [\"phone\"],
  \"query\": {
    \"match\": {
      \"role\": \"$ROLE_FILTER\"
    }
  },
  \"size\": 1000
}")

PHONES=($(echo "$RESPONSE" | jq -r '.hits.hits[]._source.phone'))

# Clean numbers
RECIPIENTS=()
for MOBILE in "${PHONES[@]}"; do
  CLEANED=$(echo "$MOBILE" | sed 's/[^0-9]//g')
  if [[ "$CLEANED" =~ ^[6-9][0-9]{9}$ ]]; then
    RECIPIENTS+=("91$CLEANED")
  elif [[ "$CLEANED" =~ ^91[6-9][0-9]{9}$ ]]; then
    RECIPIENTS+=("$CLEANED")
  else
    echo "$(date) | Skipped invalid phone: $MOBILE" >> "$LOG_FILE"
  fi
done

# --- SMS CONFIGURATION ---
USER="VGVPAY"
PASSWORD="abc123"
SENDER_ID="VGVPAY"
PE_ID="1001297681151040166"
TEMPLATE_ID="1007195263819725513"
ROUTE="07"
CHANNEL="Trans"
DCS="0"
FLASH="0"

# Start tailing alerts.json
tail -n0 -F "$ALERTS_JSON" | while read -r line; do
  [[ -z "$line" ]] && continue

  LEVEL=$(echo "$line" | jq -r '.rule.level // empty')
  HOST=$(echo "$line" | jq -r '.agent.name // empty')
  TIME=$(echo "$line" | jq -r '.timestamp // empty')
  RULE_DESC=$(echo "$line" | jq -r '.rule.description // empty')

  echo "$(date) | LEVEL=$LEVEL | HOST=$HOST | TIME=$TIME | RULE=$RULE_DESC" >> "$LOG_FILE"

  if [[ "$LEVEL" =~ ^[0-9]+$ && "$LEVEL" -ge 3 ]]; then
    SHORT_HOST=$(echo "$HOST" | cut -c1-40)
    SHORT_TIME=$(echo "$TIME" | cut -c1-30)
    VAR_MSG="$LEVEL on $SHORT_HOST at $SHORT_TIME"
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
