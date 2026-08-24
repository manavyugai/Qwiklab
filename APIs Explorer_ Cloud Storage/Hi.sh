#!/bin/bash

# ============================================================
#        GOOGLE CLOUD STORAGE 
# ============================================================

# ---------- COLORS ----------
CYAN=$'\033[38;5;51m'
PURPLE=$'\033[38;5;141m'
GREEN=$'\033[38;5;82m'
YELLOW=$'\033[38;5;220m'
WHITE=$'\033[38;5;255m'
RED=$'\033[38;5;203m'
BLUE=$'\033[38;5;39m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

clear

# ---------- HEADER ----------
echo
echo "${CYAN}${BOLD}╭──────────────────────────────────────────────────────╮${RESET}"
echo "${PURPLE}${BOLD}│              GOOGLE CLOUD STORAGE LAB               │${RESET}"
echo "${CYAN}${BOLD}╰──────────────────────────────────────────────────────╯${RESET}"
echo
echo "${WHITE}Automating Cloud Storage bucket and file operations${RESET}"
echo

# ---------- PROJECT ----------
PROJECT_ID="${DEVSHELL_PROJECT_ID}"

echo "${YELLOW}${BOLD}▸ Project Configuration${RESET}"
echo "${WHITE}  Project ID : ${PROJECT_ID}${RESET}"
echo

# ---------- STEP 1 ----------
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${PURPLE}${BOLD}  [1] CREATE CLOUD STORAGE BUCKETS${RESET}"
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

gcloud storage buckets create "gs://${PROJECT_ID}" \
    --project="${PROJECT_ID}" \
    --location=US

gcloud storage buckets create "gs://${PROJECT_ID}-2" \
    --project="${PROJECT_ID}" \
    --location=US

echo "${GREEN}${BOLD}✓ Buckets created successfully${RESET}"
echo

# ---------- STEP 2 ----------
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${PURPLE}${BOLD}  [2] DOWNLOAD SAMPLE FILES${RESET}"
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image1.png

curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image2.png

curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/APIs%20Explorer%3A%20Cloud%20Storage/demo-image1-copy.png
echo "${GREEN}${BOLD}✓ Sample files downloaded${RESET}"
echo

# ---------- STEP 3 ----------
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${PURPLE}${BOLD}  [3] UPLOAD FILES TO CLOUD STORAGE${RESET}"
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo "${BLUE}Uploading demo-image1.png...${RESET}"
gcloud storage cp demo-image1.png \
    "gs://${PROJECT_ID}/demo-image1.png"

echo "${BLUE}Uploading demo-image2.png...${RESET}"
gcloud storage cp demo-image2.png \
    "gs://${PROJECT_ID}/demo-image2.png"

echo "${BLUE}Uploading demo-image1-copy.png...${RESET}"
gcloud storage cp demo-image1-copy.png \
    "gs://${PROJECT_ID}-2/demo-image1-copy.png"

echo
echo "${GREEN}${BOLD}✓ All files uploaded successfully${RESET}"
echo

# ---------- STEP 4 ----------
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${PURPLE}${BOLD}  [4] VERIFY UPLOADED FILES${RESET}"
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo "${YELLOW}Bucket 1 contents:${RESET}"
gcloud storage ls "gs://${PROJECT_ID}/"

echo
echo "${YELLOW}Bucket 2 contents:${RESET}"
gcloud storage ls "gs://${PROJECT_ID}-2/"

echo

# ---------- CLEANUP ----------
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${PURPLE}${BOLD}  [5] CLEANUP${RESET}"
echo "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

rm -f demo-image1.png
rm -f demo-image2.png
rm -f demo-image1-copy.png

SCRIPT_NAME="cloud-storage-lab.sh"

if [ -f "$SCRIPT_NAME" ]; then
    rm -f "$SCRIPT_NAME"
fi

echo "${GREEN}${BOLD}✓ Local temporary files removed${RESET}"
echo

# ---------- COMPLETION ----------
echo "${GREEN}${BOLD}╭──────────────────────────────────────────────────────╮${RESET}"
echo "${GREEN}${BOLD}│              ✓ LAB COMPLETED SUCCESSFULLY           │${RESET}"
echo "${GREEN}${BOLD}╰──────────────────────────────────────────────────────╯${RESET}"
echo
echo "${WHITE}${BOLD}Completed Operations:${RESET}"
echo "${WHITE}  ✓ Cloud Storage buckets created${RESET}"
echo "${WHITE}  ✓ Sample files downloaded${RESET}"
echo "${WHITE}  ✓ Files uploaded using gcloud storage${RESET}"
echo "${WHITE}  ✓ Uploaded files verified${RESET}"
echo "${WHITE}  ✓ Temporary files cleaned up${RESET}"
echo
echo "${CYAN}${BOLD}Cloud Storage operation completed.${RESET}"
echo
