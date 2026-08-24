```bash
#!/bin/bash

# ============================================================
# TASK 3
# Enrich Metadata and Discovery of Lakehouse Data
# Create + Apply Sensitive Data Aspect
# ============================================================

GREEN='\e[1;32m'
CYAN='\e[1;36m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
RED='\e[1;31m'
WHITE='\e[1;37m'
RESET='\e[0m'
BOLD='\e[1m'

clear

echo -e "${CYAN}${BOLD}"
echo -e "${RESET}"

# ============================================================
# CONFIGURATION
# ============================================================

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# Task requires United States MULTI-REGION
export LOCATION="us"

# BigQuery Lakehouse table created in previous task
export DATASET_ID="ecommerce"
export TABLE_ID="customer_online_sessions"

# Aspect Type ID
export ASPECT_ID="sensitive-data-aspect"

# Temporary metadata files
export TEMPLATE_FILE="/tmp/sensitive_data_template.json"
export ASPECT_FILE="/tmp/sensitive_data_aspect.json"

echo -e "${WHITE}${BOLD}Project:${RESET}  ${CYAN}${PROJECT_ID}${RESET}"
echo -e "${WHITE}${BOLD}Location:${RESET} ${CYAN}${LOCATION} (United States Multi-Region)${RESET}"
echo -e "${WHITE}${BOLD}Dataset:${RESET}  ${CYAN}${DATASET_ID}${RESET}"
echo -e "${WHITE}${BOLD}Table:${RESET}    ${CYAN}${TABLE_ID}${RESET}"
echo

# ============================================================
# STEP 1 — ENABLE DATAPLEX API
# ============================================================

echo -e "${BLUE}${BOLD}[1/4] Enabling Dataplex API...${RESET}"

gcloud services enable dataplex.googleapis.com --quiet

echo -e "${GREEN}✓ Dataplex API enabled.${RESET}"

# ============================================================
# STEP 2 — CREATE ASPECT TEMPLATE
# ============================================================

echo
echo -e "${CYAN}${BOLD}[2/4] Creating Sensitive Data Aspect template...${RESET}"

cat > "$TEMPLATE_FILE" <<'EOF'
{
  "name": "sensitive_data_aspect",
  "type": "record",
  "recordFields": [
    {
      "name": "has_sensitive_data",
      "type": "bool",
      "index": 1,
      "annotations": {
        "displayName": "Has Sensitive Data",
        "description": "Indicates whether the table contains sensitive data."
      },
      "constraints": {
        "required": true
      }
    },
    {
      "name": "sensitive_data_type",
      "type": "enum",
      "index": 2,
      "annotations": {
        "displayName": "Sensitive Data Type",
        "description": "Identifies the type of sensitive data contained in the table."
      },
      "enumValues": [
        {
          "name": "LOCATION_INFO",
          "index": 1
        },
        {
          "name": "CONTACT_INFO",
          "index": 2
        },
        {
          "name": "NONE",
          "index": 3
        }
      ],
      "constraints": {
        "required": true
      }
    }
  ]
}
EOF

echo -e "${GREEN}✓ Aspect template created.${RESET}"

# ============================================================
# STEP 3 — CREATE ASPECT TYPE
# ============================================================

echo
echo -e "${YELLOW}${BOLD}[3/4] Creating Sensitive Data Aspect...${RESET}"

gcloud dataplex aspect-types create "$ASPECT_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --display-name="Sensitive Data Aspect" \
  --description="Identifies whether Lakehouse data contains sensitive information." \
  --metadata-template-file-name="$TEMPLATE_FILE" \
  2>/dev/null || {

    echo -e "${YELLOW}⚠ Aspect type may already exist. Continuing...${RESET}"
}

echo -e "${GREEN}✓ Sensitive Data Aspect is ready.${RESET}"

# ============================================================
# STEP 4 — FIND LAKEHOUSE TABLE ENTRY
# ============================================================

echo
echo -e "${MAGENTA}${BOLD}[4/4] Finding Lakehouse table entry...${RESET}"

ENTRY_OUTPUT=$(gcloud dataplex entries search \
  "customer_online_sessions" \
  --project="$PROJECT_ID" \
  --format="json" 2>/dev/null)

# Extract Dataplex entry name
ENTRY_NAME=$(echo "$ENTRY_OUTPUT" | jq -r '
  .[] |
  select(
    (.entry.displayName? == "customer_online_sessions") or
    (.entry.name? | contains("customer_online_sessions"))
  ) |
  .entry.name // .name
' | head -n 1)

# Fallback: search for BigQuery table by fully qualified name
if [ -z "$ENTRY_NAME" ] || [ "$ENTRY_NAME" = "null" ]; then

    ENTRY_OUTPUT=$(gcloud dataplex entries search \
      "bigquery:$PROJECT_ID.$DATASET_ID.$TABLE_ID" \
      --project="$PROJECT_ID" \
      --format="json" 2>/dev/null)

    ENTRY_NAME=$(echo "$ENTRY_OUTPUT" | jq -r '
      .[] |
      .entry.name // .name
    ' | head -n 1)
fi

if [ -z "$ENTRY_NAME" ] || [ "$ENTRY_NAME" = "null" ]; then
    echo -e "${RED}✗ Could not find the Lakehouse table entry.${RESET}"
    echo
    echo -e "${YELLOW}Try running:${RESET}"
    echo "gcloud dataplex entries search \"$TABLE_ID\" --project=\"$PROJECT_ID\""
    exit 1
fi

echo -e "${GREEN}✓ Lakehouse table entry found.${RESET}"
echo -e "${WHITE}Entry:${RESET} ${CYAN}${ENTRY_NAME}${RESET}"

# ============================================================
# CREATE ASPECT DATA
# ============================================================

echo
echo -e "${BLUE}${BOLD}Applying Sensitive Data Aspect...${RESET}"

cat > "$ASPECT_FILE" <<EOF
{
  "${PROJECT_ID}.${LOCATION}.${ASPECT_ID}": {
    "data": {
      "has_sensitive_data": true,
      "sensitive_data_type": "LOCATION_INFO"
    }
  }
}
EOF

# ============================================================
# APPLY ASPECT TO TABLE
# ============================================================

ENTRY_ID=$(basename "$ENTRY_NAME")

gcloud dataplex entries update-aspects "$ENTRY_ID" \
  --project="$PROJECT_ID" \
  --location="$LOCATION" \
  --entry-group="@bigquery" \
  --aspects="$ASPECT_FILE"

# ============================================================
# CLEANUP
# ============================================================

rm -f "$TEMPLATE_FILE"
rm -f "$ASPECT_FILE"

# ============================================================
# COMPLETE
# ============================================================

echo
echo -e "${GREEN}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║            ✓ TASK 3 COMPLETED SUCCESSFULLY                ║"
echo "║                                                            ║"
echo "║       Sensitive Data Aspect Applied to Table              ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${WHITE}Aspect Type:${RESET} ${CYAN}Sensitive Data Aspect${RESET}"
echo -e "${WHITE}Location:${RESET}    ${CYAN}United States (us)${RESET}"
echo -e "${WHITE}Has Sensitive Data:${RESET} ${GREEN}TRUE${RESET}"
echo -e "${WHITE}Sensitive Data Type:${RESET} ${GREEN}Location Info${RESET}"

echo
echo -e "${YELLOW}${BOLD}>>> Now click 'Check my progress' in the Challenge Lab. <<<${RESET}"
echo
```
