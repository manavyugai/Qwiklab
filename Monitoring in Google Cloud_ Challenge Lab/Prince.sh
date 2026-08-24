#!/bin/bash

# ================= COLORS & FORMATTING =================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
REVERSE_TEXT=$'\033[7m'

clear

# ================= WELCOME =================
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     WELCOME TO MANAVYUG AI : SUBSCRIBE NOW    ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}     Expert Tutorial by PRINCE     ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Learn more: ${UNDERLINE_TEXT}https://www.youtube.com/@manavyugai${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BLINK_TEXT}⚡ Initializing Cloud Monitoring Setup...${RESET_FORMAT}"
echo

# ================= INSTANCE SETUP =================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬▬▬ INSTANCE SETUP ▬▬▬▬▬▬${RESET_FORMAT}"

ZONE=$(gcloud compute instances list \
  --project=$DEVSHELL_PROJECT_ID \
  --format='value(ZONE)' | head -n 1)

INSTANCE_ID=$(gcloud compute instances describe apache-vm \
  --zone=$ZONE \
  --format='value(id)')

VM_EXTERNAL_IP=$(gcloud compute instances describe apache-vm \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "${CYAN_TEXT}${REVERSE_TEXT} Zone: $ZONE ${RESET_FORMAT}"
echo "${CYAN_TEXT}${REVERSE_TEXT} Instance ID: $INSTANCE_ID ${RESET_FORMAT}"
echo "${CYAN_TEXT}${REVERSE_TEXT} External IP: $VM_EXTERNAL_IP ${RESET_FORMAT}"
echo

# ================= MONITORING AGENT =================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬ MONITORING AGENT SETUP ▬▬▬▬${RESET_FORMAT}"

cat > cp_disk.sh <<'EOF'
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
sudo bash add-logging-agent-repo.sh --also-install

curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh --also-install

(cd /etc/stackdriver/collectd.d/ && sudo curl -O \
https://raw.githubusercontent.com/Stackdriver/stackdriver-agent-service-configs/master/etc/collectd.d/apache.conf)

sudo service stackdriver-agent restart
EOF

gcloud compute scp cp_disk.sh apache-vm:/tmp --zone=$ZONE --quiet
gcloud compute ssh apache-vm --zone=$ZONE --quiet --command="bash /tmp/cp_disk.sh"

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Monitoring agent installed${RESET_FORMAT}"
echo

# ================= UPTIME CHECK =================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬ UPTIME CHECK ▬▬▬▬${RESET_FORMAT}"

gcloud monitoring uptime create drabhishek \
  --resource-type=uptime-url \
  --resource-labels=host=$VM_EXTERNAL_IP,path=/,port=80

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Uptime check created${RESET_FORMAT}"
echo

# ================= NOTIFICATION CHANNEL =================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬ NOTIFICATION CHANNEL ▬▬▬▬${RESET_FORMAT}"

cat > email-channel.json <<EOF
{
  "type": "email",
  "displayName": "drabhishek",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF

gcloud beta monitoring channels create \
  --channel-content-from-file=email-channel.json

CHANNEL_ID=$(gcloud beta monitoring channels list \
  --format="value(name)" | head -n 1)

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Notification channel created${RESET_FORMAT}"
echo

# ================= ALERT POLICY =================
# Section 5: Alert Policy
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬ ALERT POLICY ▬▬▬▬▬▬▬▬${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🚨 Creating alert policy...${RESET_FORMAT}"
channel_info=$(gcloud beta monitoring channels list)
channel_id=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > app-engine-error-percent-policy.json <<EOF_CP
{
  "displayName": "alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - Traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/apache/traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "300s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 3072
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_CP

gcloud alpha monitoring policies create --policy-from-file="app-engine-error-percent-policy.json"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Alert policy created successfully!${RESET_FORMAT}"
echo
# ================= LOG-BASED METRIC =================
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬ LOG-BASED METRIC ▬▬▬▬${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)

gcloud logging metrics create drabhi \
  --description="Count Apache 200 OK responses" \
  --log-filter='resource.type="gce_instance"
logName="projects/'"$PROJECT_ID"'/logs/apache-access"
textPayload:"200"'

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Log-based metric 'drabhi' created${RESET_FORMAT}"
echo
# Section 6: Quick Links
echo "${GREEN_TEXT}${BOLD_TEXT}▬▬▬▬▬▬▬▬ QUICK LINKS ▬▬▬▬▬▬▬▬${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📊 Dashboard: ${YELLOW_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/monitoring/dashboards?&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}📈 Metrics: ${YELLOW_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/logs/metrics/edit?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo
# ================= COMPLETE =================
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}            🎉 LAB COMPLETE SUCCESSFULLY 🎉             ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📺 Subscribe: https://www.youtube.com/@manavyugai${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Happy Monitoring 🚀${RESET_FORMAT}"
