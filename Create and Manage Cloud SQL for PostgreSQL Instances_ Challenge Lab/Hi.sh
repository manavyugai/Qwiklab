# Variables auto-fetch
export PROJECT_ID=$(gcloud config get-value project)
export VM_NAME=$(gcloud compute instances list --format="value(name)" | grep postgres)
export ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(zone)")
export REGION=${ZONE%-*}

# Fixed promote command with location in resource path
gcloud datamigration migration-jobs promote projects/$PROJECT_ID/locations/$REGION/migrationJobs/migration-job --quiet
