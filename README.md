# Wazuh SMS Alert Integration (via OrainTele SMS API)

This integration continuously monitors Wazuh alerts (`alerts.json`) and sends **SMS notifications** in real time to designated mobile numbers when alerts of **level ≥ 3** are detected.

Prerequisites
Ensure the following are installed:
```
apt update
apt install jq curl -y
```
Configuration
Script Variables
```
Edit inside the script /var/ossec/active-response/bin/custom:
```
```
RECIPIENTS=("919669288387" "919103283623") # Mobile numbers
USER="VGVPAY"
PASSWORD="abc123"
SENDER_ID="VGVPAY"
PE_ID="1001297681151040166"
TEMPLATE_ID="1007195263819725513"
```
Setup Instructions
1. Place and Make Executable
```
cp custom.sh /var/ossec/active-response/bin/custom.sh
chmod +x /var/ossec/active-response/bin/custom.sh
```
2. Create Systemd Service
```
[Unit]
Description=Wazuh SMS Alert Monitor Service (custom script)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/var/ossec/active-response/bin/custom.sh
Restart=always
RestartSec=5
StandardOutput=null
StandardError=journal
User=root

[Install]
WantedBy=multi-user.target

```
3. Enable and Start the Service
```
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wazuh-sms-monitor.service
systemctl start wazuh-sms-monitor.service
```
Testing
Simulate an Alert:
```
echo '{"rule":{"level":5,"description":"SSH brute force detected"},"agent":{"name":"foreman.vgipl.com"},"timestamp":"2025-07-21T16:45:00Z"}' >> /var/ossec/logs/alerts/alerts.json
```
Verify Log Output:
```
tail -f /var/ossec/logs/integrations_sms_monitor.log
```
You should see:

```
LEVEL=5 | HOST=foreman.vgipl.com | TIME=2025-07-21T16:45:00Z
Sending SMS to 91966XXXXX | VAR=5 on foreman.vgipl.com at 2025-07-21T16:45:00Z
```
And receive:

```
ALERT 5 on foreman.vgipl.com at 2025-07-21T16:45:00Z: Unusual system access detected. Immediate review needed. from: CyberSentinel
```
Log Location
All runtime activity and SMS responses are logged here:

```
/var/ossec/logs/integrations_sms_monitor.log
```
DLT Template Compliance
The script ensures:

Max length of {#var#} ≤ 50 characters

Text matches the template exactly

Variables like hostname and timestamp are dynamically injected

DLT Template Used:

```
ALERT {#var#}: Unusual system access detected. Immediate review needed. from: CyberSentinel
```

File Summary
Path	Description
```
/var/ossec/active-response/bin/custom.sh	Main alert monitor script
/var/ossec/logs/alerts/alerts.json	Live alert feed from Wazuh
/var/ossec/logs/integrations_sms_monitor.log	Log file for SMS integration
/etc/systemd/system/wazuh-sms-monitor.service	Persistent systemd service
```

