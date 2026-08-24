#!/bin/bash
set -eo pipefail

# Style formatting
BOLD="$(tput bold)"
GREEN="$(tput setaf 2)"
CYAN="$(tput setaf 6)"
YELLOW="$(tput setaf 3)"
RED="$(tput setaf 1)"
NC="$(tput sgr0)"

log_step() {
    echo -e "\n${BOLD}${CYAN}[*] $1${NC}"
}

log_success() {
    echo -e "${BOLD}${GREEN}[+] $1${NC}"
}

log_warn() {
    echo -e "${BOLD}${YELLOW}[!] $1${NC}"
}

clean_bucket_name() {
    echo "$1" | sed -E 's/^(gs:\/\/)?([^/]+).*/\2/'
}

# Auto-detect Project and Token configuration
export PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
export REGION="us"

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Error: Cloud project could not be detected. Authenticate first.${NC}"
    exit 1
fi

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${BOLD}   SENSITIVE DATA PROTECTION AUTOMATION ENGINE     ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Project ID: ${BOLD}${GREEN}${PROJECT_ID}${NC}\n"

# Collect lab variables with smart fallback defaults
read -r -p "Enter Redact Bucket name [${PROJECT_ID}-redact]: " RAW_REDACT
read -r -p "Enter Input Bucket name  [${PROJECT_ID}-input]: " RAW_INPUT
read -r -p "Enter Output Bucket name [${PROJECT_ID}-output]: " RAW_OUTPUT

REDACT_BUCKET="$(clean_bucket_name "${RAW_REDACT:-${PROJECT_ID}-redact}")"
INPUT_BUCKET="$(clean_bucket_name "${RAW_INPUT:-${PROJECT_ID}-input}")"
OUTPUT_BUCKET="$(clean_bucket_name "${RAW_OUTPUT:-${PROJECT_ID}-output}")"

get_auth_token() {
    gcloud auth print-access-token
}

# ---------------------------------------------------------
# Task 1: Direct Content De-identification
# ---------------------------------------------------------
log_step "Executing Task 1: Redacting sensitive payload..."

cat <<'EOF' > /tmp/payload-redact.json
{
  "item": {
    "value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
  },
  "deidentifyConfig": {
    "infoTypeTransformations": {
      "transformations": [
        {
          "primitiveTransformation": {
            "replaceWithInfoTypeConfig": {}
          }
        }
      ]
    }
  },
  "inspectConfig": {
    "infoTypes": [
      { "name": "EMAIL_ADDRESS" },
      { "name": "US_HEALTHCARE_NPI" }
    ]
  }
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $(get_auth_token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/content:deidentify" \
  -d @/tmp/payload-redact.json -o redact-response.txt

gcloud storage cp redact-response.txt "gs://${REDACT_BUCKET}/" >/dev/null 2>&1
log_success "Task 1 completed & output pushed to gs://${REDACT_BUCKET}"

# ---------------------------------------------------------
# Task 2: Provision DLP De-identification Templates
# ---------------------------------------------------------
log_step "Executing Task 2: Creating Structured & Unstructured Templates..."

# 2a. Structured Template
cat <<'EOF' > /tmp/template-struct.json
{
  "deidentifyTemplate": {
    "displayName": "structured_data_template",
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              { "name": "bank name" },
              { "name": "zip code" }
            ],
            "primitiveTransformation": {
              "characterMaskConfig": {
                "maskingCharacter": "#"
              }
            }
          },
          {
            "fields": [
              { "name": "message" }
            ],
            "infoTypeTransformations": {
              "transformations": [
                {
                  "primitiveTransformation": {
                    "replaceWithInfoTypeConfig": {}
                  }
                }
              ]
            }
          }
        ]
      }
    }
  },
  "locationId": "us",
  "templateId": "structured_data_template"
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $(get_auth_token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/deidentifyTemplates" \
  -d @/tmp/template-struct.json >/dev/null

# 2b. Unstructured Template
cat <<'EOF' > /tmp/template-unstruct.json
{
  "deidentifyTemplate": {
    "displayName": "unstructured_data_template",
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          }
        ]
      }
    }
  },
  "locationId": "us",
  "templateId": "unstructured_data_template"
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $(get_auth_token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/deidentifyTemplates" \
  -d @/tmp/template-unstruct.json >/dev/null

log_success "Task 2 templates registered successfully"

# ---------------------------------------------------------
# Task 3: Configure and Trigger DLP Job
# ---------------------------------------------------------
log_step "Executing Task 3: Building Inspection Trigger..."

cat <<EOF > /tmp/job-trigger-config.json
{
  "triggerId": "dlp_job",
  "jobTrigger": {
    "displayName": "dlp_job",
    "triggers": [
      {
        "schedule": {
          "recurrencePeriodDuration": "604800s"
        }
      }
    ],
    "inspectJob": {
      "actions": [
        {
          "deidentify": {
            "fileTypesToTransform": [
              "TEXT_FILE",
              "IMAGE",
              "CSV",
              "TSV"
            ],
            "transformationConfig": {
              "deidentifyTemplate": "projects/${PROJECT_ID}/locations/${REGION}/deidentifyTemplates/unstructured_data_template",
              "structuredDeidentifyTemplate": "projects/${PROJECT_ID}/locations/${REGION}/deidentifyTemplates/structured_data_template"
            },
            "cloudStorageOutput": "gs://${OUTPUT_BUCKET}"
          }
        }
      ],
      "inspectConfig": {
        "infoTypes": [
          { "name": "EMAIL_ADDRESS" },
          { "name": "US_HEALTHCARE_NPI" },
          { "name": "PHONE_NUMBER" },
          { "name": "PERSON_NAME" },
          { "name": "CREDIT_CARD_NUMBER" },
          { "name": "US_SOCIAL_SECURITY_NUMBER" }
        ],
        "minLikelihood": "POSSIBLE"
      },
      "storageConfig": {
        "cloudStorageOptions": {
          "filesLimitPercent": 100,
          "fileSet": {
            "regexFileSet": {
              "bucketName": "${INPUT_BUCKET}",
              "includeRegex": [],
              "excludeRegex": []
            }
          }
        }
      }
    },
    "status": "HEALTHY"
  }
}
EOF

curl -s -X POST \
  -H "Authorization: Bearer $(get_auth_token)" \
  -H "Content-Type: application/json" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/jobTriggers" \
  -d @/tmp/job-trigger-config.json >/dev/null

log_step "Synchronizing trigger registration (15 seconds)..."
for ((sec=15; sec>0; sec--)); do
    printf "\r${YELLOW}Time remaining: %02d s${NC}" "$sec"
    sleep 1
done
echo ""

log_step "Activating DLP Job Trigger..."
curl -s -X POST \
  -H "Authorization: Bearer $(get_auth_token)" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/jobTriggers/dlp_job:activate" >/dev/null

log_success "Task 3 trigger active!"

# Clean temporary artifacts
rm -f /tmp/payload-redact.json /tmp/template-struct.json /tmp/template-unstruct.json /tmp/job-trigger-config.json

echo -e "\n${BOLD}${GREEN}====================================================${NC}"
echo -e "${BOLD}${GREEN}  ALL TASKS PROVISIONED - VERIFY ON THE LAB PAGE    ${NC}"
echo -e "${BOLD}${GREEN}====================================================${NC}"
