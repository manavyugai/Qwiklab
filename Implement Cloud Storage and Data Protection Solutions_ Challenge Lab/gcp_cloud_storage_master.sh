#!/bin/bash

set -e

echo "=========================================="
echo "   GCP CLOUD STORAGE MASTER SCRIPT"
echo "=========================================="

# Auto-detect project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo "❌ Project ID detect nahi hua."
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo ""
echo "✅ Project ID: $PROJECT_ID"

# Region
echo ""
read -p "Enter Region [us-west1]: " REGION
REGION=${REGION:-us-west1}

# Bucket names
echo ""
read -p "Enter Bucket1 name: " BUCKET1
read -p "Enter Bucket2 name: " BUCKET2
read -p "Enter Bucket3 name: " BUCKET3

if [ -z "$BUCKET1" ] || [ -z "$BUCKET2" ] || [ -z "$BUCKET3" ]; then
    echo "❌ Bucket names empty nahi ho sakte."
    exit 1
fi

echo ""
echo "=========================================="
echo "PROJECT : $PROJECT_ID"
echo "REGION  : $REGION"
echo "BUCKET1 : $BUCKET1"
echo "BUCKET2 : $BUCKET2"
echo "BUCKET3 : $BUCKET3"
echo "=========================================="

# Set project and region
gcloud config set project "$PROJECT_ID" >/dev/null
gcloud config set compute/region "$REGION" >/dev/null

# TASK 1: Bucket1 - Coldline
echo ""
echo "=========================================="
echo "TASK 1: Bucket1 - COLDLINE"
echo "=========================================="

if gcloud storage buckets describe "gs://$BUCKET1" >/dev/null 2>&1; then
    echo "ℹ️ Bucket1 already exists."
else
    gcloud storage buckets create "gs://$BUCKET1" \
        --location="$REGION" \
        --default-storage-class=COLDLINE
    echo "✅ Bucket1 created with COLDLINE."
fi

# TASK 2: Bucket2 - 30 second retention
echo ""
echo "=========================================="
echo "TASK 2: Bucket2 - 30s RETENTION"
echo "=========================================="

if ! gcloud storage buckets describe "gs://$BUCKET2" >/dev/null 2>&1; then
    echo "❌ Bucket2 does not exist."
    echo "This lab expects Bucket2 to be pre-created."
    exit 1
fi

gcloud storage buckets update "gs://$BUCKET2" \
    --retention-period=30s

echo "✅ Bucket2 retention policy set to 30 seconds."

# TASK 3: Upload object to Bucket3
echo ""
echo "=========================================="
echo "TASK 3: UPLOAD OBJECT TO BUCKET3"
echo "=========================================="

if ! gcloud storage buckets describe "gs://$BUCKET3" >/dev/null 2>&1; then
    echo "❌ Bucket3 does not exist."
    echo "This lab expects Bucket3 to be pre-created."
    exit 1
fi

TEMP_FILE="lab-object.txt"
echo "Cloud Storage Lab Object - $PROJECT_ID" > "$TEMP_FILE"

gcloud storage cp "$TEMP_FILE" "gs://$BUCKET3/"
rm -f "$TEMP_FILE"

echo "✅ Object uploaded to Bucket3."

# Verification
echo ""
echo "=========================================="
echo "VERIFICATION"
echo "=========================================="

echo ""
echo "🔹 Bucket1:"
gcloud storage buckets describe "gs://$BUCKET1" \
    --format="default(name,location,storageClass)"

echo ""
echo "🔹 Bucket2:"
gcloud storage buckets describe "gs://$BUCKET2" \
    --format="default(name,retentionPolicy)"

echo ""
echo "🔹 Bucket3 objects:"
gcloud storage ls "gs://$BUCKET3"

echo ""
echo "=========================================="
echo "✅ ALL 3 TASKS COMPLETED"
echo "=========================================="
