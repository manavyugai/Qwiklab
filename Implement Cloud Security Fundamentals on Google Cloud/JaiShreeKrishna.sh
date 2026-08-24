#!/bin/bash

# ============================================================
# MANAVYUG AI
# ============================================================

clear

# ---------- Terminal Colors ----------
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}==============================================${RESET}"
echo -e "${CYAN}        SUBSCRIBE GUYS                        ${RESET}"
echo -e "${CYAN}==============================================${RESET}"
echo

read -p "Enter CUSTOM_SECURITY_ROLE: " CUSTOM_SECURITY_ROLE
read -p "Enter SERVICE_ACCOUNT: " SERVICE_ACCOUNT
read -p "Enter CLUSTER_NAME: " CLUSTER_NAME
read -p "Enter ZONE: " ZONE

echo
echo -e "${YELLOW}Configuring Compute Zone...${RESET}"

gcloud config set compute/zone "$ZONE"

# ---------- IAM Role Definition ----------
cat > role-definition.yaml <<EOF
title: "$CUSTOM_SECURITY_ROLE"
description: "Permissions"
stage: "ALPHA"
includedPermissions:
- storage.buckets.get
- storage.objects.get
- storage.objects.list
- storage.objects.update
- storage.objects.create
EOF

echo -e "${YELLOW}Creating service account...${RESET}"

gcloud iam service-accounts create orca-private-cluster-sa \
    --display-name="Orca Private Cluster Service Account"

echo -e "${YELLOW}Creating custom IAM role...${RESET}"

gcloud iam roles create "$CUSTOM_SECURITY_ROLE" \
    --project "$DEVSHELL_PROJECT_ID" \
    --file role-definition.yaml

echo -e "${YELLOW}Creating requested service account...${RESET}"

gcloud iam service-accounts create "$SERVICE_ACCOUNT" \
    --display-name="Orca Private Cluster Service Account"

# ---------- Project IAM Bindings ----------
echo -e "${YELLOW}Applying IAM permissions...${RESET}"

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member "serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role roles/monitoring.viewer

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member "serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member "serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role roles/logging.logWriter

gcloud projects add-iam-policy-binding "$DEVSHELL_PROJECT_ID" \
    --member "serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role "projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_SECURITY_ROLE"

# ---------- Private GKE Cluster ----------
echo -e "${YELLOW}Creating private GKE cluster...${RESET}"

gcloud container clusters create "$CLUSTER_NAME" \
    --num-nodes 1 \
    --master-ipv4-cidr=172.16.0.64/28 \
    --network orca-build-vpc \
    --subnetwork orca-build-subnet \
    --enable-master-authorized-networks \
    --master-authorized-networks 192.168.10.2/32 \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --service-account "$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --zone "$ZONE"

# ---------- Jump Host Configuration ----------
echo -e "${YELLOW}Configuring jump host...${RESET}"

gcloud compute ssh --zone "$ZONE" "orca-jumphost" \
    --project "$DEVSHELL_PROJECT_ID" \
    --quiet \
    --command "
gcloud config set compute/zone $ZONE &&
gcloud container clusters get-credentials $CLUSTER_NAME --internal-ip &&
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin &&
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0 &&
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 80 \
--target-port 8080
"

echo
echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}       Lab Completed Successfully             ${RESET}"
echo -e "${GREEN}==============================================${RESET}"
