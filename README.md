# sms-service
smsc integration through service creation 

0. Create the script

1. Make it executable
chmod +x /var/ossec/active-response/bin/custom

2. Ensure your systemd unit is using this script
Check /etc/systemd/system/wazuh-sms-monitor.service:

3. Start and use Service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable wazuh-sms-monitor.service
sudo systemctl restart wazuh-sms-monitor.service

You should see a proper SMS dispatch with the VAR_MSG filled correctly and a "Response" line from the SMS API.

