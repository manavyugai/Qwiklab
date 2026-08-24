#!/bin/bash

# ============================================================
# ARC123 TERMINAL AUTOMATION
# Unified Script: Steps 1–6
# ============================================================

# ---------- COLORS ----------
GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
RED='\e[1;31m'
WHITE='\e[1;37m'
RESET='\e[0m'
BOLD='\e[1m'

# ---------- CLEAR SCREEN ----------
clear

# ---------- HEADER ----------
echo -e "${CYAN}${BOLD}"
echo -e "${RESET}"

echo -e "${MAGENTA}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        ARC123 AUTOMATION SYSTEM             ║"
echo "║       BigLake + BigQuery Infrastructure Deployment        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ---------- PROJECT ----------
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

echo
echo -e "${WHITE}${BOLD}┌─ SYSTEM INFORMATION ──────────────────────────────────────┐${RESET}"
echo -e "${WHITE}│ Project ID : ${CYAN}${PROJECT_ID}${RESET}"
echo -e "${WHITE}│ Region     : ${CYAN}US${RESET}"
echo -e "${WHITE}│ Mode       : ${GREEN}AUTOMATED${RESET}"
echo -e "${WHITE}└────────────────────────────────────────────────────────────┘${RESET}"

# ============================================================
# STEP 1
# ============================================================

echo
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}${BOLD}  [01/06] ⚙ ENABLE REQUIRED GOOGLE CLOUD APIs${RESET}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

gcloud services enable \
    datacatalog.googleapis.com \
    bigqueryconnection.googleapis.com \
    dataplex.googleapis.com \
    --quiet

echo -e "${GREEN}✔ Required APIs enabled successfully.${RESET}"

# ============================================================
# STEP 2
# ============================================================

echo
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}${BOLD}  [02/06] 🗄 CREATE BIGQUERY DATASET${RESET}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

bq mk \
    --location=US \
    ecommerce \
    2>/dev/null || true

echo -e "${GREEN}✔ BigQuery dataset 'ecommerce' is ready.${RESET}"

# ============================================================
# STEP 3
# ============================================================

echo
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${YELLOW}${BOLD}  [03/06] 🔗 CREATE CLOUD RESOURCE CONNECTION${RESET}"
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

bq mk \
    --connection \
    --location=US \
    --project_id="$PROJECT_ID" \
    --connection_type=CLOUD_RESOURCE \
    customer_data_connection \
    2>/dev/null || true

echo -e "${GREEN}✔ Cloud Resource Connection is ready.${RESET}"

# ============================================================
# STEP 4
# ============================================================

echo
echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${MAGENTA}${BOLD}  [04/06] 🔐 CONFIGURE SERVICE ACCOUNT PERMISSIONS${RESET}"
echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

export SERVICE_ACCOUNT=$(bq show \
    --format=json \
    --connection \
    "$PROJECT_ID.US.customer_data_connection" \
    | jq -r '.cloudResource.serviceAccountId')

echo -e "${WHITE}Service Account:${RESET} ${CYAN}${SERVICE_ACCOUNT}${RESET}"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/storage.objectViewer" \
    --quiet

echo -e "${GREEN}✔ Storage Object Viewer permission granted.${RESET}"

# ============================================================
# STEP 5
# ============================================================

echo
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}${BOLD}  [05/06] 📄 CREATE BIGLAKE TABLE DEFINITION${RESET}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

bq mkdef \
    --autodetect \
    --connection_id="$PROJECT_ID.US.customer_data_connection" \
    --source_format=CSV \
    "gs://$PROJECT_ID-bucket/customer-online-sessions.csv" \
    > /tmp/tabledef.json

echo -e "${GREEN}✔ BigLake table definition generated.${RESET}"

# ============================================================
# STEP 6
# ============================================================

echo
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}${BOLD}  [06/06] 🌐 CREATE EXTERNAL LAKEHOUSE TABLE${RESET}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

bq mk \
    --external_table_definition=/tmp/tabledef.json \
    --project_id="$PROJECT_ID" \
    ecommerce.customer_online_sessions \
    2>/dev/null || true

# ---------- CLEANUP ----------
rm -f /tmp/tabledef.json 2>/dev/null

# ============================================================
# COMPLETION
# ============================================================

echo
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              🚀 DEPLOYMENT COMPLETE! 🚀                   ║"
echo "║                                                            ║"
echo "║     ARC123 BigLake Infrastructure is READY                ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${WHITE}${BOLD}"
echo "  Project      : ${CYAN}${PROJECT_ID}${RESET}"
echo -e "${WHITE}  Dataset      : ${CYAN}ecommerce${RESET}"
echo -e "${WHITE}  Connection   : ${CYAN}customer_data_connection${RESET}"
echo -e "${WHITE}  Table        : ${CYAN}customer_online_sessions${RESET}"
echo -e "${WHITE}  Source       : ${CYAN}gs://${PROJECT_ID}-bucket/customer-online-sessions.csv${RESET}"

echo
echo -e "${YELLOW}${BOLD}>>> INFRASTRUCTURE COMPLETE! <<<${RESET}"
echo -e "${MAGENTA}>>> Follow the remaining Cloud Console UI steps for Task 3. <<<${RESET}"
echo
```
