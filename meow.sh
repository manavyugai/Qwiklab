#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define color variables
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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE MANAVYUG AI- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Retrieve Google Cloud environment defaults
PROJECT_ID=$(gcloud config get-value project)

echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Please Enter Your Region (e.g., us-central1): ${RESET_FORMAT}"
read REGION

echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Please Enter Your Zone (e.g., us-central1-a): ${RESET_FORMAT}"
read ZONE

echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Please Enter Your Cloud SQL Instance Name: ${RESET_FORMAT}"
read SQL_INSTANCE_NAME

# Enable API
echo "${CYAN_TEXT}${BOLD_TEXT}Enabling required services...${RESET_FORMAT}"
gcloud services enable networkconnectivity.googleapis.com

# Task 1: Create Hub
echo "${CYAN_TEXT}${BOLD_TEXT}Task 1. Create a hub... Please wait.${RESET_FORMAT}"
gcloud network-connectivity hubs create ncc-hub

gcloud config set accessibility/screen_reader false
gcloud compute networks subnets list --network=vpc1-ncc

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating spokes...${RESET_FORMAT}"
gcloud network-connectivity spokes linked-vpc-network create vpc1-spoke1 \
  --hub=ncc-hub \
  --vpc-network=vpc1-ncc \
  --exclude-export-ranges=10.1.2.0/24 \
  --global

echo "${CYAN_TEXT}${BOLD_TEXT}Configure VPC2 as an NCC spoke...${RESET_FORMAT}"
gcloud network-connectivity spokes linked-vpc-network create vpc2-spoke2 \
  --hub=ncc-hub \
  --vpc-network=vpc2-ncc \
  --exclude-export-ranges=10.3.3.0/24 \
  --global

# Task 4: Private Service Connect Setup
echo "${GREEN_TEXT}${BOLD_TEXT}Task 4. Set up Private Service Connect...${RESET_FORMAT}"

gcloud compute networks subnets describe vpc2-ncc-subnet1 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(ipCidrRange)"

echo "${BLUE_TEXT}${BOLD_TEXT}Creating static internal IP address...${RESET_FORMAT}"
gcloud compute addresses create cloudsql-psc \
  --project=$PROJECT_ID \
  --region=$REGION \
  --subnet=vpc2-ncc-subnet1 \
  --addresses=10.2.2.70

echo "${YELLOW_TEXT}${BOLD_TEXT}Verify internal IP address...${RESET_FORMAT}"
gcloud compute addresses list \
  --project=$PROJECT_ID \
  --filter="name=cloudsql-psc"

# Fetch PSC Service Attachment Link
echo "${CYAN_TEXT}${BOLD_TEXT}Service Attachment Link for ${SQL_INSTANCE_NAME}:${RESET_FORMAT}"
gcloud sql instances describe $SQL_INSTANCE_NAME \
  --project=$PROJECT_ID \
  --format="value(pscServiceAttachmentLink)"

echo -ne "${YELLOW_TEXT}${BOLD_TEXT}Enter Service_Attachment_URI : ${RESET_FORMAT}"
read SERVICE_ATTACHMENT_URI

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating PSC forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create cloudsql-psc-ep \
  --address=cloudsql-psc \
  --project=$PROJECT_ID \
  --region=$REGION \
  --network=vpc2-ncc \
  --target-service-attachment=$SERVICE_ATTACHMENT_URI \
  --allow-psc-global-access

echo "${MAGENTA_TEXT}${BOLD_TEXT}Configure a DNS managed zone...${RESET_FORMAT}"
gcloud dns managed-zones create cloudsql-dns \
  --project=$PROJECT_ID \
  --description="DNS zone for the Cloud SQL instances" \
  --dns-name=$REGION.sql.goog. \
  --networks=vpc2-ncc \
  --visibility=private

echo "${MAGENTA_TEXT}${BOLD_TEXT}DNS Name for ${SQL_INSTANCE_NAME}:${RESET_FORMAT}"
gcloud sql instances describe $SQL_INSTANCE_NAME \
  --project=$PROJECT_ID \
  --format="value(dnsName)"

echo -ne "${MAGENTA_TEXT}${BOLD_TEXT}ENTER DNS_RECORD : ${RESET_FORMAT}"
read DNS_RECORD_NAME

gcloud dns record-sets create $DNS_RECORD_NAME \
  --project=$PROJECT_ID \
  --type=A \
  --rrdatas=10.2.2.70 \
  --zone=cloudsql-dns

# Task 5: SSH Connection
echo "${MAGENTA_TEXT}${BOLD_TEXT}Task 5. Connect to Cloud SQL via Private Service Connect.${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE" "cloudsql-client" \
  --tunnel-through-iap --project "$PROJECT_ID"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@ManavYugAI${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
