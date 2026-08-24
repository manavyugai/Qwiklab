#!/bin/bash

# ==============================
#        COLOR SETTINGS
# ==============================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# ==============================
#       TEXT FORMATTING
# ==============================
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# ==============================
#          START BANNER
# ==============================
echo
echo "${BLUE_TEXT}${BOLD_TEXT}╔══════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}║${WHITE_TEXT}              GCP LAB EXECUTION STARTED                    ${BLUE_TEXT}║${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}║${CYAN_TEXT}                 SUBSCRIBE TECH & CODE                     ${BLUE_TEXT}║${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}╚══════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}▶ Initializing Google Cloud environment...${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)

echo "${CYAN_TEXT}▶ Creating Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb -l $REGION -c Standard gs://$PROJECT_ID

echo "${CYAN_TEXT}▶ Downloading required file...${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Cloud%20Storage%3A%20Qwik%20Start%20-%20Google%20Cloud%20Console/kitten.png

echo "${CYAN_TEXT}▶ Uploading file to Cloud Storage...${RESET_FORMAT}"
gsutil cp kitten.png gs://$PROJECT_ID/kitten.png

echo "${CYAN_TEXT}▶ Updating bucket permissions...${RESET_FORMAT}"
gsutil iam ch allUsers:objectViewer gs://$PROJECT_ID

# ==============================
#        SUCCESS MESSAGE
# ==============================
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔══════════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}║${WHITE_TEXT}                    ✓ LAB COMPLETED                       ${GREEN_TEXT}║${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}║${WHITE_TEXT}                  SUCCESSFULLY!                            ${GREEN_TEXT}║${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚══════════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

