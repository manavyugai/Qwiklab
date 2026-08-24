#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
PINK_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${PINK_TEXT}${BOLD_TEXT}🔍  Downloading the code...${RESET_FORMAT}"
gcloud storage cp gs://qwiklabs-gcp-01-930932499f42-bucket/user-authentication-with-iap.zip .

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Region successfully set to: $REGION${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️  Downloaded sucessfully...${RESET_FORMAT}"
unzip user-authentication-with-iap.zip
echo

echo "${CYAN_TEXT}${BOLD_TEXT}👤 Change the directory.${RESET_FORMAT}"
cd user-authentication-with-iap
cd 1-HelloWorld
echo

echo "${PINK_TEXT}${BOLD_TEXT}📄  Deploy to Cloud Run..${RESET_FORMAT}"
gcloud run deploy user-auth-lab --source . --allow-unauthenticated --region=us-central1
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📥 Task 2. Access user identity information...${RESET_FORMAT}"
cd ~/user-authentication-with-iap/2-HelloUser
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📦  Deploy to Cloud Run...${RESET_FORMAT}"
gcloud run deploy user-auth-lab --source . --region=us-central1
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Task 3. Use cryptographic verification..${RESET_FORMAT}"
cd ~/user-authentication-with-iap/3-HelloVerifiedUser


echo
echo "${PINK_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

