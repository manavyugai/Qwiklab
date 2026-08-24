#!/bin/bash
set -e

# Define color variables
BOLD=$(tput bold)
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)

function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you created hello-cloudbuild & hello-cloudbuild-deploy ($REGION) with ^candidate$ triggers ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo -e "\n${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}\n"
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo -e "\n${BOLD}${RED}Please create hello-cloudbuild & hello-cloudbuild-deploy ($REGION) with ^candidate$ triggers and then press Y to continue.${RESET}"
        else
            echo -e "\n${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

echo "${BOLD}${GREEN}Starting Execution...${RESET}"

# Step 1: Set environment variables
echo "${BOLD}${CYAN}Setting up environment variables${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region "$REGION"

# Step 2: Enable required services
echo "${BOLD}${YELLOW}Enabling necessary Google Cloud services${RESET}"
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com

# Step 3: Create Artifact Registry repository
echo "${BOLD}${BLUE}Creating Artifact Registry repository${RESET}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location="$REGION" || true

# Step 4: Create GKE cluster
echo "${BOLD}${MAGENTA}Creating GKE Cluster${RESET}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region "$REGION"

# Step 5: Install & Authenticate GitHub CLI
echo "${BOLD}${CYAN}Installing and Authenticating GitHub CLI${RESET}"
curl -sS https://webi.sh/gh | sh
export PATH="$HOME/.local/bin:$PATH"

gh auth login
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL:-admin@example.com}"

# Step 6: Create GitHub Repositories
echo "${BOLD}${YELLOW}Creating GitHub repositories${RESET}"
gh repo create hello-cloudbuild-app --private || true
gh repo create hello-cloudbuild-env --private || true

# Step 7: Clone Google Storage files
echo "${BOLD}${MAGENTA}Cloning source files${RESET}"
cd ~
mkdir -p hello-cloudbuild-app
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app/
cd ~/hello-cloudbuild-app

# Step 8: Update region values in files
echo "${BOLD}${CYAN}Updating region values in configuration files${RESET}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

# Step 9: Initialize git repository
echo "${BOLD}${GREEN}Initializing Git repository${RESET}"
git init
git config credential.helper gcloud.sh
git remote add google "https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app"
git branch -m master
git add . && git commit -m "initial commit"

# Step 10: Submit build to Cloud Build
echo "${BOLD}${BLUE}Submitting build to Cloud Build${RESET}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

echo -e "\n${BOLD}${BLUE}Click here to set up triggers:${RESET} https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID"

check_progress

# Step 11: Push changes to GitHub app repo
echo "${BOLD}${MAGENTA}Pushing changes to GitHub${RESET}"
git add .
git commit -m "Update configurations" || true
git push google master

# Step 12: Create SSH Key for GitHub authentication
echo "${BOLD}${CYAN}Generating SSH key for GitHub${RESET}"
mkdir -p ~/workingdir
cd ~/workingdir
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL:-admin@example.com}"

# Step 13: Store SSH key in Secret Manager
echo "${BOLD}${GREEN}Storing SSH key in Secret Manager${RESET}"
gcloud secrets create ssh_key_secret --replication-policy="automatic" || true
gcloud secrets versions add ssh_key_secret --data-file=id_github

# Step 14: Add SSH key to GitHub
echo "${BOLD}${BLUE}Adding SSH key to GitHub${RESET}"
SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)
gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  "/repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys" \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false
rm -f id_github*

# Step 15: Grant IAM permissions
echo "${BOLD}${YELLOW}Granting IAM permissions${RESET}"
gcloud projects add-iam-policy-binding "${PROJECT_NUMBER}" \
--member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding "${PROJECT_NUMBER}" \
--member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
--role="roles/container.developer"

# Step 16: Setup environment repository
echo "${BOLD}${MAGENTA}Setting up environment repository${RESET}"
cd ~
mkdir -p hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env/

cd ~/hello-cloudbuild-env
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git init
git config credential.helper gcloud.sh
git remote add google "https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env"
git branch -m master
git add . && git commit -m "initial commit"
git push google master

# Step 17: Create deployment branches and local cloudbuild configurations
echo "${BOLD}${GREEN}Configuring deployment pipeline${RESET}"
git checkout -b production

cat <<EOF > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/kubectl'
  args:
  - 'apply'
  - '-f'
  - 'kubernetes.yaml'
  env:
  - 'CLOUDSDK_COMPUTE_ZONE=$REGION'
  - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cloudbuild'
EOF

git add .
git commit -m "Create cloudbuild.yaml for deployment"
git checkout -b candidate

git push google production
git push google candidate

# Step 18: Trigger CD pipeline
echo "${BOLD}${YELLOW}Triggering the CD pipeline${RESET}"
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git add .
git commit -m "Adding known_host file." || true
git push google master

cat <<EOF > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:\$SHORT_SHA', '.']
- name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:\$SHORT_SHA']
- name: 'gcr.io/cloud-builders/git'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    chmod 600 id_github
    cat <<EOFK > ~/.ssh/config
    Host github.com
      IdentityFile $(pwd)/id_github
      StrictHostKeyChecking no
    EOFK
    git clone git@github.com:${GITHUB_USERNAME}/hello-cloudbuild-env.git
    cd hello-cloudbuild-env
    git checkout candidate
    sed -i 's#image:.*#image: ${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:'"\$SHORT_SHA"'#' kubernetes.yaml
    git add kubernetes.yaml
    git commit -m "Deploying image ${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:\$SHORT_SHA"
    git push origin candidate
EOF

git add cloudbuild.yaml
git commit -m "Trigger CD pipeline"
git push google master

echo -e "\n${BOLD}${GREEN}Lab completed successfully!${RESET}\n"
