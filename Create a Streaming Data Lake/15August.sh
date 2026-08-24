#!/bin/bash

GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
RED='\e[1;31m'
RESET='\e[0m'
BOLD='\e[1m'

clear

echo -e "${CYAN}${BOLD}"
echo "============================================================"
echo "        STREAMING DATA LAKE ON CLOUD STORAGE"
echo "============================================================"
echo -e "${RESET}"

# ============================================================
# PROJECT ID
# ============================================================

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
    echo -e "${RED}Project ID not found.${RESET}"
    exit 1
fi

echo -e "${GREEN}Project ID:${RESET} $PROJECT_ID"

# ============================================================
# LAB INPUTS
# ============================================================

echo
echo -e "${YELLOW}${BOLD}Enter the exact values given in your lab.${RESET}"
echo

read -p "Enter Pub/Sub topic name: " TOPIC

if [[ -z "$TOPIC" ]]; then
    echo -e "${RED}Topic name cannot be empty.${RESET}"
    exit 1
fi

read -p "Enter message/input text: " MESSAGE

if [[ -z "$MESSAGE" ]]; then
    echo -e "${RED}Message cannot be empty.${RESET}"
    exit 1
fi

read -p "Enter Cloud Storage bucket name: " BUCKET

if [[ -z "$BUCKET" ]]; then
    echo -e "${RED}Bucket name cannot be empty.${RESET}"
    exit 1
fi

read -p "Enter Region (example: europe-west1): " REGION

if [[ -z "$REGION" ]]; then
    echo -e "${RED}Region cannot be empty.${RESET}"
    exit 1
fi

# ============================================================
# ZONE
# ============================================================

ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" \
    2>/dev/null | tail -n 1)

if [[ -z "$ZONE" ]]; then
    ZONE="${REGION}-d"
fi

# ============================================================
# DISPLAY CONFIGURATION
# ============================================================

echo
echo -e "${CYAN}${BOLD}Lab Configuration:${RESET}"
echo "------------------------------------------------------------"
echo "Project ID    : $PROJECT_ID"
echo "Pub/Sub Topic : $TOPIC"
echo "Message       : $MESSAGE"
echo "Bucket        : $BUCKET"
echo "Region        : $REGION"
echo "Zone          : $ZONE"
echo "------------------------------------------------------------"

read -p "Press Enter to continue..."

# ============================================================
# CONFIGURE GOOGLE CLOUD
# ============================================================

echo
echo -e "${BLUE}${BOLD}[1/7] Configuring Google Cloud...${RESET}"

gcloud config set project "$PROJECT_ID" --quiet
gcloud config set compute/region "$REGION" --quiet
gcloud config set compute/zone "$ZONE" --quiet

echo -e "${GREEN}✓ Done${RESET}"

# ============================================================
# ENABLE APIs
# ============================================================

echo
echo -e "${BLUE}${BOLD}[2/7] Enabling required APIs...${RESET}"

gcloud services enable \
    pubsub.googleapis.com \
    cloudscheduler.googleapis.com \
    appengine.googleapis.com \
    dataflow.googleapis.com \
    --quiet

sleep 15

echo -e "${GREEN}✓ APIs enabled${RESET}"

# ============================================================
# CREATE PUB/SUB TOPIC
# ============================================================

echo
echo -e "${BLUE}${BOLD}[3/7] Creating Pub/Sub topic...${RESET}"

if gcloud pubsub topics describe "$TOPIC" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Topic already exists. Skipping.${RESET}"
else
    gcloud pubsub topics create "$TOPIC" --quiet

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Failed to create Pub/Sub topic.${RESET}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Pub/Sub topic ready${RESET}"

# ============================================================
# APP ENGINE REGION
# ============================================================

# App Engine uses a different region format for some regions.

AE_REGION="$REGION"

if [[ "$REGION" == "us-central1" ]]; then
    AE_REGION="us-central"
elif [[ "$REGION" == "europe-west1" ]]; then
    AE_REGION="europe-west"
elif [[ "$REGION" == "asia-east1" ]]; then
    AE_REGION="asia-east"
elif [[ "$REGION" == "us-east1" ]]; then
    AE_REGION="us-east"
fi

# ============================================================
# APP ENGINE + CLOUD SCHEDULER
# ============================================================

echo
echo -e "${BLUE}${BOLD}[4/7] Configuring App Engine and Cloud Scheduler...${RESET}"

gcloud app create \
    --region="$AE_REGION" \
    --quiet 2>/dev/null || true

gcloud scheduler jobs create pubsub publisher-job \
    --schedule="* * * * *" \
    --topic="$TOPIC" \
    --message-body="$MESSAGE" \
    --location="$REGION" \
    --quiet 2>/dev/null

if [[ $? -ne 0 ]]; then

    echo -e "${YELLOW}⚠ Scheduler job already exists. Updating...${RESET}"

    gcloud scheduler jobs update pubsub publisher-job \
        --schedule="* * * * *" \
        --topic="$TOPIC" \
        --message-body="$MESSAGE" \
        --location="$REGION" \
        --quiet
fi

echo -e "${GREEN}✓ Scheduler configured${RESET}"

# ============================================================
# RUN SCHEDULER
# ============================================================

echo
echo -e "${BLUE}Starting scheduler job...${RESET}"

gcloud scheduler jobs run publisher-job \
    --location="$REGION" \
    --quiet

echo -e "${GREEN}✓ Scheduler started${RESET}"

# ============================================================
# CREATE CLOUD STORAGE BUCKET
# ============================================================

echo
echo -e "${BLUE}${BOLD}[5/7] Creating Cloud Storage bucket...${RESET}"

if gcloud storage buckets describe "gs://$BUCKET" >/dev/null 2>&1; then

    echo -e "${YELLOW}⚠ Bucket already exists. Skipping.${RESET}"

else

    gcloud storage buckets create \
        "gs://$BUCKET" \
        --location="$REGION" \
        --quiet

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Failed to create bucket.${RESET}"
        exit 1
    fi

fi

echo -e "${GREEN}✓ Bucket ready${RESET}"

# ============================================================
# PREPARE DATAFLOW ENVIRONMENT
# ============================================================

echo
echo -e "${BLUE}${BOLD}[6/7] Preparing Dataflow environment...${RESET}"

cd "$HOME"

if [[ ! -d "$HOME/df-env" ]]; then
    python3 -m venv df-env
fi

source "$HOME/df-env/bin/activate"

echo -e "${GREEN}✓ Virtual environment activated${RESET}"

# ============================================================
# DOWNLOAD GOOGLE CLOUD SAMPLES
# ============================================================

if [[ ! -d "$HOME/python-docs-samples" ]]; then

    echo -e "${YELLOW}Downloading Google Cloud samples...${RESET}"

    git clone \
        https://github.com/GoogleCloudPlatform/python-docs-samples.git

else

    echo -e "${YELLOW}Google Cloud samples already exist.${RESET}"

fi

cd "$HOME/python-docs-samples/pubsub/streaming-analytics"

# ============================================================
# INSTALL REQUIREMENTS
# ============================================================

echo -e "${YELLOW}Installing Python requirements...${RESET}"

python -m pip install --upgrade pip
pip install --upgrade -r requirements.txt

# ============================================================
# MODIFY DATAFLOW SAMPLE
# ============================================================

if grep -q "result.wait_until_finish()" PubSubToGCS.py; then

    sed -i \
        's/result.wait_until_finish()/\# result.wait_until_finish()/g' \
        PubSubToGCS.py

fi

echo -e "${GREEN}✓ Dataflow environment ready${RESET}"

# ============================================================
# SUBMIT DATAFLOW PIPELINE
# ============================================================

echo
echo -e "${BLUE}${BOLD}[7/7] Submitting Dataflow pipeline...${RESET}"

echo
echo -e "${CYAN}Dataflow Configuration:${RESET}"
echo "------------------------------------------------------------"
echo "Project       : $PROJECT_ID"
echo "Region        : $REGION"
echo "Input Topic   : projects/$PROJECT_ID/topics/$TOPIC"
echo "Output Path   : gs://$BUCKET/samples/output"
echo "Window Size   : 2 minutes"
echo "Num Shards    : 2"
echo "Worker        : e2-standard-2"
echo "Disk          : pd-standard"
echo "------------------------------------------------------------"
echo

python PubSubToGCS.py \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --input_topic="projects/$PROJECT_ID/topics/$TOPIC" \
    --output_path="gs://$BUCKET/samples/output" \
    --runner=DataflowRunner \
    --window_size=2 \
    --num_shards=2 \
    --temp_location="gs://$BUCKET/temp" \
    --worker_machine_type="e2-standard-2" \
    --worker_disk_type="pd-standard"

if [[ $? -ne 0 ]]; then
    echo
    echo -e "${RED}${BOLD}✗ Dataflow pipeline submission failed.${RESET}"
    exit 1
fi

# ============================================================
# FINAL
# ============================================================

echo
echo -e "${GREEN}${BOLD}"
echo "============================================================"
echo "                 ✓ LAB TASKS COMPLETED"
echo "============================================================"
echo -e "${RESET}"

echo "Project ID    : $PROJECT_ID"
echo "Pub/Sub Topic : $TOPIC"
echo "Message       : $MESSAGE"
echo "Bucket        : $BUCKET"
echo "Region        : $REGION"

echo
echo -e "${YELLOW}${BOLD}Dataflow job has been submitted.${RESET}"
echo
echo "Wait for the Dataflow job to start and output files"
echo "to appear in the Cloud Storage bucket."
echo
echo "Then click 'Check my progress' in the lab."
echo
