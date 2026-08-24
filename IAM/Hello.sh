#!/bin/bash

# ============================================================
#              🚀 IAM CUSTOM ROLE EDITOR 🚀
# ============================================================

# ---------- MODERN COLOR PALETTE ----------
BLACK="\033[0;30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# ---------- DESIGN HELPERS ----------
LINE="${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo
echo "$LINE"
echo "${CYAN}${BOLD}              🔐 IAM CUSTOM ROLE EDITOR${RESET}"
echo "$LINE"
echo

echo "${YELLOW}${BOLD}▶ Starting${RESET} ${GREEN}${BOLD}Execution...${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 1 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Creating role-definition.yaml                           │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

echo 'title: "Role Editor"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- appengine.versions.create
- appengine.versions.delete' > role-definition.yaml

echo "${GREEN}✔ Role definition created${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 2 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Creating custom IAM role: editor                        │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles create editor --project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml

echo "${GREEN}✔ Editor role created${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 3 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Creating custom IAM role: viewer                        │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles create viewer --project $DEVSHELL_PROJECT_ID \
--title "Role Viewer" --description "Custom role description." \
--permissions compute.instances.get,compute.instances.list --stage ALPHA

echo "${GREEN}✔ Viewer role created${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 4 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Updating role-definition.yaml                            │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

echo 'description: Edit access for App Versions
etag:
includedPermissions:
- appengine.versions.create
- appengine.versions.delete
- storage.buckets.get
- storage.buckets.list
name: projects/'$DEVSHELL_PROJECT_ID'/roles/editor
stage: ALPHA
title: Role Editor' > new-role-definition.yaml

gcloud iam roles update editor --project $DEVSHELL_PROJECT_ID \
--file new-role-definition.yaml --quiet

echo "${GREEN}✔ Editor role updated${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 5 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Adding permissions to viewer role                       │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--add-permissions storage.buckets.get,storage.buckets.list

echo "${GREEN}✔ Permissions added${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 6 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Disabling viewer role                                    │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles update viewer --project $DEVSHELL_PROJECT_ID \
--stage DISABLED

echo "${GREEN}✔ Viewer role disabled${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 7 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Deleting viewer role                                     │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles delete viewer --project $DEVSHELL_PROJECT_ID

echo "${GREEN}✔ Viewer role deleted${RESET}"
echo

echo "${BLUE}${BOLD}┌─[ STEP 8 ]──────────────────────────────────────────────┐${RESET}"
echo "${WHITE}│ Restoring viewer role                                    │${RESET}"
echo "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${RESET}"

gcloud iam roles undelete viewer --project $DEVSHELL_PROJECT_ID

echo "${GREEN}✔ Viewer role restored${RESET}"
echo

echo "$LINE"
echo "${GREEN}${BOLD}                 🎉 CONGRATULATIONS 🎉${RESET}"
echo "${WHITE}${BOLD}              for Completing the Lab !!!${RESET}"
echo "$LINE"
echo
