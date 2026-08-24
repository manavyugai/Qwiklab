#!/bin/bash

# ==============================================================================
# APIGEE AUTOMATION SCRIPT
# ==============================================================================

# ---------- COLORS ----------
C1='\033[1;36m'
C2='\033[1;32m'
C3='\033[1;33m'
C4='\033[1;35m'
C5='\033[1;37m'
C6='\033[1;31m'
NC='\033[0m'


# ---------- HEADER ----------
clear

echo -e "${C1}"
echo "╭──────────────────────────────────────────────────────────────╮"
echo "│                                                              │"
echo "│              APIGEE AUTOMATION TOOL                         │"
echo "│                                                              │"
echo "│        API PROXY  •  IAM  •  PRODUCT  •  APP               │"
echo "│                                                              │"
echo "╰──────────────────────────────────────────────────────────────╯"
echo -e "${NC}"

echo -e "${C5}Initializing environment...${NC}"
sleep 1


# ==============================================================================
# PROJECT DETECTION
# ==============================================================================

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
    echo -e "${C6}"
    echo "ERROR: No active Google Cloud project found."
    echo -e "${NC}"
    exit 1
fi

echo
echo -e "${C2}✔ Project detected:${NC} ${C5}${PROJECT_ID}${NC}"
echo


# ==============================================================================
# SERVICE ACCOUNT + IAM
# ==============================================================================

echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 01  ${C1}▸${NC} API & IAM CONFIGURATION"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Enabling Translation API...${NC}"

gcloud services enable translate.googleapis.com --quiet

echo -e "${C2}✔ Translation API enabled${NC}"

echo
echo -e "${C3}→ Creating Apigee service account...${NC}"

gcloud iam service-accounts create apigee-proxy \
    --display-name="Apigee Proxy Service Access" \
    --quiet 2>/dev/null || true

echo -e "${C2}✔ Service account ready${NC}"

echo
echo -e "${C3}→ Assigning Logging Writer role...${NC}"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:apigee-proxy@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter" \
    --quiet

echo -e "${C2}✔ IAM role configured${NC}"


# ==============================================================================
# IAM PROPAGATION
# ==============================================================================

echo
echo -e "${C3}→ Waiting for IAM propagation...${NC}"

for i in {30..1}; do
    printf "\r   Remaining: %02d seconds " "$i"
    sleep 1
done

echo
echo -e "${C2}✔ IAM propagation completed${NC}"


# ==============================================================================
# APIGEE INSTANCE
# ==============================================================================

INSTANCE_NAME="eval-instance"
ENV_NAME="eval"

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 02  ${C1}▸${NC} APIGEE RUNTIME"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Waiting for Apigee instance...${NC}"
echo -e "${C3}  This process may take several minutes.${NC}"
echo

PREV_INSTANCE_STATE=""

while true; do

    ACCESS_TOKEN=$(gcloud auth print-access-token)

    INSTANCE_STATE=$(curl -s \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/instances/${INSTANCE_NAME}" \
        | jq -r '.state // empty')

    if [[ "$INSTANCE_STATE" != "$PREV_INSTANCE_STATE" ]]; then
        echo
        echo -e "   ${C3}Instance state:${NC} ${C5}${INSTANCE_STATE:-UNKNOWN}${NC}"
        PREV_INSTANCE_STATE="$INSTANCE_STATE"
    fi

    if [[ "$INSTANCE_STATE" == "ACTIVE" ]]; then
        break
    fi

    printf "."
    sleep 15
done

echo
echo -e "${C2}✔ Apigee instance is ACTIVE${NC}"


# ==============================================================================
# ENVIRONMENT ATTACHMENT
# ==============================================================================

echo
echo -e "${C3}→ Checking environment attachment...${NC}"

while true; do

    ACCESS_TOKEN=$(gcloud auth print-access-token)

    ATTACHMENT_DONE=$(curl -s \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/instances/${INSTANCE_NAME}/attachments" \
        | jq -r \
        "select(.attachments != null) |
         .attachments[] |
         select(.environment == \"${ENV_NAME}\") |
         .environment" \
        --join-output)

    if [[ "$ATTACHMENT_DONE" == "$ENV_NAME" ]]; then
        break
    fi

    printf "."
    sleep 15
done

echo
echo -e "${C2}✔ Environment attached successfully${NC}"


# ==============================================================================
# DOWNLOAD PROXY
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 03  ${C1}▸${NC} API PROXY"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Downloading API proxy bundle...${NC}"

curl -L \
    "https://drive.google.com/uc?export=download&id=1IxJMjqAJ-FVKWOdg2HnJ79wY7BBlbjbJ" \
    -o translate-v1.zip \
    --silent \
    --show-error

if [[ ! -f "translate-v1.zip" ]]; then
    echo -e "${C6}✖ Proxy bundle download failed${NC}"
    exit 1
fi

echo -e "${C2}✔ Proxy bundle downloaded${NC}"


# ==============================================================================
# IMPORT PROXY
# ==============================================================================

echo
echo -e "${C3}→ Importing API proxy...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/apis?action=import&name=translate-v1" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @translate-v1.zip

echo
echo -e "${C2}✔ API proxy imported${NC}"


# ==============================================================================
# DEPLOY PROXY
# ==============================================================================

echo
echo -e "${C3}→ Deploying API proxy...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/environments/${ENV_NAME}/apis/translate-v1/revisions/1/deployments?serviceAccount=apigee-proxy@${PROJECT_ID}.iam.gserviceaccount.com" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"

echo
echo -e "${C2}✔ API proxy deployed${NC}"


# ==============================================================================
# API PRODUCT
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 04  ${C1}▸${NC} API PRODUCT"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cat > translate-product.json <<EOF
{
  "name": "translate-product",
  "displayName": "translate-product",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    }
  ],
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "translate-v1",
        "operations": [
          {
            "resource": "/",
            "methods": [
              "GET",
              "POST"
            ]
          }
        ],
        "quota": {
          "limit": "10",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF

echo -e "${C3}→ Creating API product...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/apiproducts" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @translate-product.json

echo
echo -e "${C2}✔ API product created${NC}"


# ==============================================================================
# DEVELOPER
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 05  ${C1}▸${NC} DEVELOPER ACCOUNT"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Creating developer account...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/developers" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "joe@example.com",
      "firstName": "Joe",
      "lastName": "Developer",
      "userName": "joe"
    }'

echo
echo -e "${C2}✔ Developer account configured${NC}"


# ==============================================================================
# DEVELOPER APP
# ==============================================================================

echo
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${C5}STEP 06  ${C1}▸${NC} DEVELOPER APPLICATION"
echo -e "${C1}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${C3}→ Creating translate-app...${NC}"

ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -s -X POST \
    "https://apigee.googleapis.com/v1/organizations/${PROJECT_ID}/developers/joe@example.com/apps" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "translate-app",
      "apiProducts": [
        "translate-product"
      ]
    }'

echo
echo -e "${C2}✔ Developer application created${NC}"


# ==============================================================================
# CLEANUP
# ==============================================================================

rm -f translate-v1.zip
rm -f translate-product.json


# ==============================================================================
# FINAL SCREEN
# ==============================================================================

echo
echo -e "${C4}"
echo "╭──────────────────────────────────────────────────────────────╮"
echo "│                                                              │"
echo "│                  ✓ OPERATION COMPLETE                       │"
echo "│                                                              │"
echo "├──────────────────────────────────────────────────────────────┤"
echo "│                                                              │"
printf "│  Project       : %-42s│\n" "$PROJECT_ID"
printf "│  Environment   : %-42s│\n" "$ENV_NAME"
printf "│  API Proxy     : %-42s│\n" "translate-v1"
printf "│  API Product   : %-42s│\n" "translate-product"
printf "│  Developer App : %-42s│\n" "translate-app"
echo "│                                                              │"
echo "╰──────────────────────────────────────────────────────────────╯"
echo -e "${NC}"

echo -e "${C2}${BOLD}All configured tasks have been completed successfully.${NC}"
echo
