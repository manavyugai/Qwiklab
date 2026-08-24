#!/bin/bash

# Define color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD} Welcome to Manavyug AI You are Eating Melody Chocolate ! ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo

# Show current authentication
echo "${MAGENTA}${BOLD}Current gcloud authentication:${RESET}"
gcloud auth list
echo

# Set environment variables
echo "${YELLOW}${BOLD}Setting up environment variables...${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

# Configure Dataflow service
echo "${BLUE}${BOLD}Configuring Dataflow service...${RESET}"
gcloud services disable dataflow.googleapis.com --project $DEVSHELL_PROJECT_ID
gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"
gcloud services enable dataflow.googleapis.com --project $DEVSHELL_PROJECT_ID

# Bigtable instance creation prompt
echo
echo "${YELLOW}${BOLD}Create Bigtable instance${RESET} ${BLUE}${BOLD}https://console.cloud.google.com/bigtable/create-instance?project=$DEVSHELL_PROJECT_ID${RESET}"
echo

while true; do
    echo -ne "${YELLOW}${BOLD}Do you want to proceed? (Y/n): ${RESET}"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo "${BLUE}${BOLD}Running the command...${RESET}"
            break
            ;;
        [Nn]|"") 
            echo "Operation canceled."
            exit 0
            ;;
        *) 
            echo "${RED}${BOLD}Invalid input. Please enter Y or N.${RESET}" 
            ;;
    esac
done

# Create storage bucket
echo "${GREEN}${BOLD}Creating storage bucket...${RESET}"
gsutil mb gs://$PROJECT_ID

# Create Bigtable tables
echo "${MAGENTA}${BOLD}Creating Bigtable tables...${RESET}"
gcloud bigtable instances tables create SessionHistory --instance=ecommerce-recommendations --project=$PROJECT_ID --column-families=Engagements,Sales
sleep 20

# Import sessions data
echo "${CYAN}${BOLD}Importing sessions data...${RESET}"
while true; do
    gcloud dataflow jobs run import-sessions --region=$REGION --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "${YELLOW}${BOLD}Job has completed successfully. Now just wait for succeeded.${RESET}"
        break
    else
        echo "${YELLOW}${BOLD}Job retrying. Please wait...${RESET}"
        sleep 10
    fi
done

# Create recommendations table
echo "${GREEN}${BOLD}Creating recommendations table...${RESET}"
gcloud bigtable instances tables create PersonalizedProducts --project=$PROJECT_ID --instance=ecommerce-recommendations --column-families=Recommendations
sleep 20

# Import recommendations data
echo "${MAGENTA}${BOLD}Importing recommendations data...${RESET}"
while true; do
    gcloud dataflow jobs run import-recommendations --region=$REGION --project=$PROJECT_ID \
        --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
        --staging-location gs://$PROJECT_ID/temp \
        --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001,mutationThrottleLatencyMs=0

    if [ $? -eq 0 ]; then
        echo "${YELLOW}${BOLD}Job has completed successfully. Now just wait for succeeded.${RESET}"
        break
    else
        echo "${YELLOW}${BOLD}Job retrying. Please wait...${RESET}"
        sleep 10
    fi
done

# Create backup
echo "${CYAN}${BOLD}Creating backup...${RESET}"
gcloud beta bigtable backups create PersonalizedProducts_7 --instance=ecommerce-recommendations --cluster=ecommerce-recommendations-c1 --table=PersonalizedProducts --retention-period=7d 

# Restore backup
echo "${BLUE}${BOLD}Restoring backup...${RESET}"
gcloud beta bigtable instances tables restore --source=projects/$PROJECT_ID/instances/ecommerce-recommendations/clusters/ecommerce-recommendations-c1/backups/PersonalizedProducts_7 --async --destination=PersonalizedProducts_7_restored --destination-instance=ecommerce-recommendations --project=$PROJECT_ID

# Check job status prompt
echo
echo "${YELLOW}${BOLD}Check job status${RESET} ${BLUE}${BOLD}https://console.cloud.google.com/dataflow/jobs?project=$DEVSHELL_PROJECT_ID${RESET}"
echo

while true; do
    echo -ne "${YELLOW}${BOLD}Do you want to proceed with cleanup? (Y/n): ${RESET}"
    read confirm
    case "$confirm" in
        [Yy]) 
            echo "${BLUE}${BOLD}Running cleanup commands...${RESET}"
            break
            ;;
        [Nn]|"") 
            echo "Cleanup canceled."
            exit 0
            ;;
        *) 
            echo "${RED}${BOLD}Invalid input. Please enter Y or N.${RESET}" 
            ;;
    esac
done

# Cleanup resources
echo "${RED}${BOLD}Cleaning up resources...${RESET}"
gcloud bigtable instances tables delete PersonalizedProducts --instance=ecommerce-recommendations --quiet
gcloud bigtable instances tables delete PersonalizedProducts_7_restored --instance=ecommerce-recommendations --quiet
gcloud bigtable instances tables delete SessionHistory --instance=ecommerce-recommendations --quiet
gcloud bigtable backups delete PersonalizedProducts_7 \
  --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 --quiet

echo
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}           You Eated Melody Chocolate Successfully!       ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${GREEN}${BOLD}Thanks for using Manavyug AI!${RESET}"
echo
