#!/bin/bash
set -e

# Prompt user for Region
read -p "Enter Region (e.g. us-central1): " REGION
export REGION

# Auto-detect Project ID
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)
echo "Project ID detected: $GOOGLE_CLOUD_PROJECT"

# ----------------------------------------------------
# Task 1: Clone the source repository & setup
# ----------------------------------------------------
echo "Cloning source repository..."
cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh

# ----------------------------------------------------
# Task 2: Create Artifact Registry & Build Container (v1.0.0)
# ----------------------------------------------------
echo "Enabling required APIs..."
gcloud services enable artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com

echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create monolith-demo \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository" || true

echo "Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

echo "Building and pushing container v1.0.0..."
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0

# ----------------------------------------------------
# Task 3: Deploy the container to Cloud Run
# ----------------------------------------------------
echo "Deploying monolith to Cloud Run..."
gcloud run deploy monolith \
    --image ${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --quiet

# ----------------------------------------------------
# Task 4: Create new revision with lower concurrency
# ----------------------------------------------------
echo "Deploying new revision with concurrency 1..."
gcloud run deploy monolith \
    --image ${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:1.0.0 \
    --region $REGION \
    --platform managed \
    --concurrency 1 \
    --allow-unauthenticated \
    --quiet

# ----------------------------------------------------
# Task 5: Make changes to the website & Build v2.0.0
# ----------------------------------------------------
echo "Updating website code..."
cd ~/monolith-to-microservices/react-app/src/pages/Home
mv index.js.new index.js

echo "Building React app..."
cd ~/monolith-to-microservices/react-app
npm run build:monolith

echo "Building and pushing container v2.0.0..."
cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0

# ----------------------------------------------------
# Task 6: Update website with zero downtime
# ----------------------------------------------------
echo "Deploying monolith v2.0.0 to Cloud Run..."
gcloud run deploy monolith \
    --image ${REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/monolith-demo/monolith:2.0.0 \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --quiet

echo "Lab completed successfully!"
