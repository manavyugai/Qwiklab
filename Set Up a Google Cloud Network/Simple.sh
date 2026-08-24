#!/bin/bash
set -e

# Configuration variables
VPC_NAME=""
SUBNET_A=""
SUBNET_B=""
FIREWALL_1=""
FIREWALL_2=""
FIREWALL_3=""
ZONE_1="us-central1-a"
ZONE_2="us-east1-b"

# Derived variables
REGION_1="${ZONE_1%-*}"
REGION_2="${ZONE_2%-*}"
VM_1="us-test-01"
VM_2="us-test-02"

# 1. Create VPC
gcloud compute networks create "$VPC_NAME" \
    --project="$DEVSHELL_PROJECT_ID" \
    --subnet-mode=custom \
    --mtu=1460 \
    --bgp-routing-mode=regional

# 2. Create Subnets
gcloud compute networks subnets create "$SUBNET_A" \
    --project="$DEVSHELL_PROJECT_ID" \
    --region="$REGION_1" \
    --network="$VPC_NAME" \
    --range=10.10.10.0/24 \
    --stack-type=IPV4_ONLY

gcloud compute networks subnets create "$SUBNET_B" \
    --project="$DEVSHELL_PROJECT_ID" \
    --region="$REGION_2" \
    --network="$VPC_NAME" \
    --range=10.10.20.0/24 \
    --stack-type=IPV4_ONLY

# 3. Create Firewall Rules
gcloud compute firewall-rules create "$FIREWALL_1" \
    --project="$DEVSHELL_PROJECT_ID" \
    --network="$VPC_NAME" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=all

gcloud compute firewall-rules create "$FIREWALL_2" \
    --project="$DEVSHELL_PROJECT_ID" \
    --network="$VPC_NAME" \
    --direction=INGRESS \
    --priority=65535 \
    --action=ALLOW \
    --rules=tcp:3389 \
    --source-ranges=0.0.0.0/24 \
    --target-tags=all

gcloud compute firewall-rules create "$FIREWALL_3" \
    --project="$DEVSHELL_PROJECT_ID" \
    --network="$VPC_NAME" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules=icmp \
    --source-ranges=0.0.0.0/24 \
    --target-tags=all

# 4. Create Compute Instances
gcloud compute instances create "$VM_1" \
    --project="$DEVSHELL_PROJECT_ID" \
    --zone="$ZONE_1" \
    --subnet="$SUBNET_A" \
    --tags=allow-icmp

gcloud compute instances create "$VM_2" \
    --project="$DEVSHELL_PROJECT_ID" \
    --zone="$ZONE_2" \
    --subnet="$SUBNET_B" \
    --tags=allow-icmp

# 5. Fetch Remote IP & Validate Connection
EXTERNAL_IP_2=$(gcloud compute instances describe "$VM_2" \
    --zone="$ZONE_2" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

gcloud compute ssh "$VM_1" \
    --zone="$ZONE_1" \
    --project="$DEVSHELL_PROJECT_ID" \
    --quiet \
    --command="ping -c 3 $EXTERNAL_IP_2 && ping -c 3 $VM_2.$ZONE_2"
