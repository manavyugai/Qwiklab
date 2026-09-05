```bash
#!/bin/bash

# ============================================================
#        GSP328 - SERVERLESS CLOUD RUN CHALLENGE LAB
#        PET THEORY - COMPLETE MASTER SCRIPT
# ============================================================

clear

echo "============================================================"
echo "        GSP328 - CLOUD RUN CHALLENGE LAB"
echo "        Pet Theory Deployment Automation"
echo "============================================================"
echo

# ------------------------------------------------------------
# COLORS
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ------------------------------------------------------------
# HELPER FUNCTIONS
# ------------------------------------------------------------

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

error() {
    echo -e "${RED}[✗]${RESET} $1"
}

step() {
    echo
    echo -e "${BLUE}============================================================${RESET}"
    echo -e "${WHITE}$1${RESET}"
    echo -e "${BLUE}============================================================${RESET}"
}

# ------------------------------------------------------------
# STOP SCRIPT ON IMPORTANT ERRORS
# ------------------------------------------------------------

set -e

# ------------------------------------------------------------
# AUTHENTICATION
# ------------------------------------------------------------

step "Checking Google Cloud Authentication"

gcloud auth list

# ------------------------------------------------------------
# AUTO DETECT PROJECT
# ------------------------------------------------------------

step "Detecting Qwiklabs Project"

PROJECT_ID=$(gcloud projects list \
    --format='value(PROJECT_ID)' \
    --filter='qwiklabs-gcp' \
    | head -n 1)

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    error "Project ID could not be detected."
    exit 1
fi

export PROJECT_ID

success "Project ID: $PROJECT_ID"

gcloud config set project "$PROJECT_ID"

# ------------------------------------------------------------
# AUTO DETECT REGION
# ------------------------------------------------------------

step "Detecting Cloud Run Region"

REGION=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-region])" \
    2>/dev/null || true)

if [ -z "$REGION" ]; then
    warning "Default region was not found automatically."
    read -p "Enter REGION: " REGION
fi

export REGION

success "Region: $REGION"

gcloud config set run/region "$REGION"
gcloud config set run/platform managed

# ------------------------------------------------------------
# UNIQUE SUFFIX
# ------------------------------------------------------------

SUFFIX=$((100 + RANDOM % 900))

# ------------------------------------------------------------
# SERVICE NAMES
# ------------------------------------------------------------

PUBLIC_BILLING_SERVICE="public-billing-service-$SUFFIX"

FRONTEND_STAGING_SERVICE="frontend-staging-service-$SUFFIX"

PRIVATE_BILLING_SERVICE="private-billing-service-$SUFFIX"

BILLING_SERVICE_ACCOUNT="billing-service-sa-$SUFFIX"

BILLING_PROD_SERVICE="billing-prod-service-$SUFFIX"

FRONTEND_SERVICE_ACCOUNT="frontend-service-sa-$SUFFIX"

FRONTEND_PRODUCTION_SERVICE="frontend-prod-service-$SUFFIX"

# ------------------------------------------------------------
# DISPLAY CONFIGURATION
# ------------------------------------------------------------

step "Deployment Configuration"

echo
echo "PROJECT ID                 : $PROJECT_ID"
echo "REGION                     : $REGION"
echo
echo "Public Billing Service     : $PUBLIC_BILLING_SERVICE"
echo "Frontend Staging Service   : $FRONTEND_STAGING_SERVICE"
echo "Private Billing Service    : $PRIVATE_BILLING_SERVICE"
echo "Billing Service Account    : $BILLING_SERVICE_ACCOUNT"
echo "Billing Production Service : $BILLING_PROD_SERVICE"
echo "Frontend Service Account   : $FRONTEND_SERVICE_ACCOUNT"
echo "Frontend Production        : $FRONTEND_PRODUCTION_SERVICE"
echo

read -p "Press ENTER to start the lab deployment..."

# ============================================================
# CLONE PET THEORY REPOSITORY
# ============================================================

step "Preparing Pet Theory Repository"

cd ~

if [ -d "$HOME/pet-theory" ]; then
    warning "pet-theory directory already exists."

    cd "$HOME/pet-theory"
    git pull || true
else
    git clone https://github.com/rosera/pet-theory.git
fi

cd "$HOME/pet-theory/lab07"

success "Pet Theory repository ready."

# ============================================================
# TASK 1
# PUBLIC BILLING SERVICE
# ============================================================

step "TASK 1 - Deploy Public Billing Service"

cd "$HOME/pet-theory/lab07/unit-api-billing"

info "Building billing-staging-api:0.1"

gcloud builds submit \
    --tag "gcr.io/$PROJECT_ID/billing-staging-api:0.1"

success "Billing image built."

info "Deploying public billing service."

gcloud run deploy "$PUBLIC_BILLING_SERVICE" \
    --image "gcr.io/$PROJECT_ID/billing-staging-api:0.1" \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --quiet

PUBLIC_BILLING_URL=$(gcloud run services describe "$PUBLIC_BILLING_SERVICE" \
    --platform managed \
    --region "$REGION" \
    --format="value(status.url)")

success "Public Billing Service deployed."
echo "URL: $PUBLIC_BILLING_URL"

info "Testing public billing service."

curl -s "$PUBLIC_BILLING_URL"

echo
success "Task 1 completed."

# ============================================================
# TASK 2
# FRONTEND STAGING SERVICE
# ============================================================

step "TASK 2 - Deploy Frontend Staging Service"

cd "$HOME/pet-theory/lab07/staging-frontend-billing"

info "Building frontend-staging:0.1"

gcloud builds submit \
    --tag "gcr.io/$PROJECT_ID/frontend-staging:0.1"

success "Frontend staging image built."

info "Deploying frontend staging service."

gcloud run deploy "$FRONTEND_STAGING_SERVICE" \
    --image "gcr.io/$PROJECT_ID/frontend-staging:0.1" \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --quiet

FRONTEND_STAGING_URL=$(gcloud run services describe "$FRONTEND_STAGING_SERVICE" \
    --platform managed \
    --region "$REGION" \
    --format="value(status.url)")

success "Frontend staging service deployed."
echo "URL: $FRONTEND_STAGING_URL"

info "Testing frontend staging service."

curl -s -o /dev/null \
    -w "HTTP Status: %{http_code}\n" \
    "$FRONTEND_STAGING_URL"

success "Task 2 completed."

# ============================================================
# TASK 3
# PRIVATE BILLING SERVICE
# ============================================================

step "TASK 3 - Deploy Private Billing Service"

info "Deleting existing public billing service."

gcloud run services delete "$PUBLIC_BILLING_SERVICE" \
    --region "$REGION" \
    --platform managed \
    --quiet || true

success "Existing Billing Service removed."

cd "$HOME/pet-theory/lab07/staging-api-billing"

info "Building billing-staging-api:0.2"

gcloud builds submit \
    --tag "gcr.io/$PROJECT_ID/billing-staging-api:0.2"

success "Private billing image built."

info "Deploying authenticated private billing service."

gcloud run deploy "$PRIVATE_BILLING_SERVICE" \
    --image "gcr.io/$PROJECT_ID/billing-staging-api:0.2" \
    --region "$REGION" \
    --platform managed \
    --no-allow-unauthenticated \
    --quiet

# ------------------------------------------------------------
# BILLING URL
# ------------------------------------------------------------

BILLING_URL=$(gcloud run services describe "$PRIVATE_BILLING_SERVICE" \
    --platform managed \
    --region "$REGION" \
    --format="value(status.url)")

export BILLING_URL

success "Private Billing Service deployed."
echo "BILLING_URL=$BILLING_URL"

info "Testing private billing service with identity token."

curl -s \
    -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
    "$BILLING_URL"

echo
success "Task 3 completed."

# ============================================================
# TASK 4
# BILLING SERVICE ACCOUNT
# ============================================================

step "TASK 4 - Create Billing Service Account"

info "Creating Billing Service Account."

gcloud iam service-accounts create "$BILLING_SERVICE_ACCOUNT" \
    --display-name="Billing Service Cloud Run"

BILLING_SA_EMAIL="$BILLING_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"

export BILLING_SA_EMAIL

success "Billing Service Account created."

echo "Service Account:"
echo "$BILLING_SA_EMAIL"

# ============================================================
# TASK 5
# BILLING PRODUCTION SERVICE
# ============================================================

step "TASK 5 - Deploy Billing Production Service"

cd "$HOME/pet-theory/lab07/prod-api-billing"

info "Building billing-prod-api:0.1"

gcloud builds submit \
    --tag "gcr.io/$PROJECT_ID/billing-prod-api:0.1"

success "Production billing image built."

info "Deploying authenticated Billing Production Service."

gcloud run deploy "$BILLING_PROD_SERVICE" \
    --image "gcr.io/$PROJECT_ID/billing-prod-api:0.1" \
    --region "$REGION" \
    --platform managed \
    --no-allow-unauthenticated \
    --service-account "$BILLING_SA_EMAIL" \
    --quiet

# ------------------------------------------------------------
# PRODUCTION BILLING URL
# ------------------------------------------------------------

PROD_BILLING_URL=$(gcloud run services describe "$BILLING_PROD_SERVICE" \
    --platform managed \
    --region "$REGION" \
    --format="value(status.url)")

export PROD_BILLING_URL

success "Billing Production Service deployed."

echo
echo "PROD_BILLING_URL=$PROD_BILLING_URL"
echo

info "Testing Billing Production Service."

curl -s \
    -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
    "$PROD_BILLING_URL"

echo
success "Task 5 completed."

# ============================================================
# TASK 6
# FRONTEND SERVICE ACCOUNT
# ============================================================

step "TASK 6 - Create Frontend Service Account"

info "Creating Frontend Service Account."

gcloud iam service-accounts create "$FRONTEND_SERVICE_ACCOUNT" \
    --display-name="Billing Service Cloud Run Invoker"

FRONTEND_SA_EMAIL="$FRONTEND_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"

export FRONTEND_SA_EMAIL

success "Frontend Service Account created."

echo "Service Account:"
echo "$FRONTEND_SA_EMAIL"

# ------------------------------------------------------------
# GRANT CLOUD RUN INVOKER
# ------------------------------------------------------------

info "Granting Cloud Run Invoker permission."

gcloud run services add-iam-policy-binding "$BILLING_PROD_SERVICE" \
    --region "$REGION" \
    --platform managed \
    --member="serviceAccount:$FRONTEND_SA_EMAIL" \
    --role="roles/run.invoker"

success "run.invoker permission granted."

# ============================================================
# TASK 7
# FRONTEND PRODUCTION SERVICE
# ============================================================

step "TASK 7 - Deploy Frontend Production Service"

cd "$HOME/pet-theory/lab07/prod-frontend-billing"

info "Building frontend-prod:0.1"

gcloud builds submit \
    --tag "gcr.io/$PROJECT_ID/frontend-prod:0.1"

success "Frontend production image built."

info "Deploying Frontend Production Service."

gcloud run deploy "$FRONTEND_PRODUCTION_SERVICE" \
    --image "gcr.io/$PROJECT_ID/frontend-prod:0.1" \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --service-account "$FRONTEND_SA_EMAIL" \
    --set-env-vars="BILLING_URL=$PROD_BILLING_URL" \
    --quiet

FRONTEND_PRODUCTION_URL=$(gcloud run services describe "$FRONTEND_PRODUCTION_SERVICE" \
    --platform managed \
    --region "$REGION" \
    --format="value(status.url)")

export FRONTEND_PRODUCTION_URL

success "Frontend Production Service deployed."

echo
echo "Frontend Production URL:"
echo "$FRONTEND_PRODUCTION_URL"
echo

info "Testing Frontend Production Service."

curl -s -o /dev/null \
    -w "HTTP Status: %{http_code}\n" \
    "$FRONTEND_PRODUCTION_URL"

success "Task 7 completed."

# ============================================================
# FINAL VERIFICATION
# ============================================================

step "FINAL CLOUD RUN SERVICE VERIFICATION"

gcloud run services list \
    --platform managed \
    --region "$REGION"

# ============================================================
# FINAL SERVICE ACCOUNT VERIFICATION
# ============================================================

step "FINAL SERVICE ACCOUNT VERIFICATION"

gcloud iam service-accounts list \
    --filter="email:$PROJECT_ID.iam.gserviceaccount.com"

# ============================================================
# FINAL SUMMARY
# ============================================================

echo
echo -e "${GREEN}============================================================${RESET}"
echo -e "${GREEN}              GSP328 LAB COMPLETED${RESET}"
echo -e "${GREEN}============================================================${RESET}"
echo

echo "PROJECT ID:"
echo "$PROJECT_ID"
echo

echo "REGION:"
echo "$REGION"
echo

echo "----------------------------------------"
echo "TASK 1 - Public Billing Service"
echo "----------------------------------------"
echo "$PUBLIC_BILLING_SERVICE"
echo "$PUBLIC_BILLING_URL"
echo

echo "----------------------------------------"
echo "TASK 2 - Frontend Staging Service"
echo "----------------------------------------"
echo "$FRONTEND_STAGING_SERVICE"
echo "$FRONTEND_STAGING_URL"
echo

echo "----------------------------------------"
echo "TASK 3 - Private Billing Service"
echo "----------------------------------------"
echo "$PRIVATE_BILLING_SERVICE"
echo "$BILLING_URL"
echo

echo "----------------------------------------"
echo "TASK 4 - Billing Service Account"
echo "----------------------------------------"
echo "$BILLING_SA_EMAIL"
echo

echo "----------------------------------------"
echo "TASK 5 - Billing Production Service"
echo "----------------------------------------"
echo "$BILLING_PROD_SERVICE"
echo "$PROD_BILLING_URL"
echo

echo "----------------------------------------"
echo "TASK 6 - Frontend Service Account"
echo "----------------------------------------"
echo "$FRONTEND_SA_EMAIL"
echo

echo "----------------------------------------"
echo "TASK 7 - Frontend Production Service"
echo "----------------------------------------"
echo "$FRONTEND_PRODUCTION_SERVICE"
echo "$FRONTEND_PRODUCTION_URL"
echo

echo -e "${GREEN}============================================================${RESET}"
echo -e "${GREEN}        ALL TASKS HAVE BEEN PROCESSED SUCCESSFULLY${RESET}"
echo -e "${GREEN}============================================================${RESET}"
echo

echo "Wait approximately 30 seconds and click:"
echo "\"Check my progress\" for each task."
echo
```
