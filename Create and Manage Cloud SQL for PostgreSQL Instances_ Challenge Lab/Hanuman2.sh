clear
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[38;5;51m'
C_AMBER='\033[38;5;214m'
C_GREEN='\033[38;5;82m'
C_PURPLE='\033[38;5;141m'

echo -e "${C_PURPLE}${C_BOLD}"
cat << "EOF"
  ┌───────────────────────────────────────────────────────────┐
  │   ⚡ CLOUD SQL POSTGRESQL LAB: STAGE 2 (IAM & RECOVERY)   │
  └───────────────────────────────────────────────────────────┘
EOF
echo -e "${C_RESET}"

echo -e "${C_AMBER}📌 Enter target parameters from your lab instructions:${C_RESET}"
read -p "➔ Enter Migrated Cloud SQL Instance ID: " SQL_INSTANCE
read -p "➔ Enter Qwiklabs User Account Email: " STUDENT_EMAIL
read -p "➔ Enter Table Name (e.g., orders): " TABLE_NAME
read -p "➔ Enter PITR Retention Days (e.g., 2): " RETENTION_DAYS
echo ""

export VM_NAME=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep postgres)
export ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(zone)")
export EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo -e "${C_CYAN}🔧 [1/5] Updating Instance Configuration (IAM & Network Access)...${C_RESET}"
gcloud sql instances patch $SQL_INSTANCE \
    --database-flags cloudsql.iam_authentication=on \
    --authorized-networks=$EXTERNAL_IP \
    --enable-point-in-time-recovery \
    --retained-transaction-log-days=$RETENTION_DAYS \
    --quiet

echo -e "${C_CYAN}👤 [2/5] Registering Cloud IAM User...${C_RESET}"
gcloud sql users create $STUDENT_EMAIL \
    --instance=$SQL_INSTANCE \
    --type=CLOUD_IAM_USER

export SQL_IP=$(gcloud sql instances describe $SQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")

cat << EOF > iam_grant.sql
GRANT SELECT ON $TABLE_NAME TO "$STUDENT_EMAIL";
EOF

echo -e "${C_CYAN}🔐 [3/5] Granting SQL Database Permissions...${C_RESET}"
gcloud compute scp iam_grant.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/iam_grant.sql"

cat << EOF > test_iam.sql
SELECT COUNT(*) FROM $TABLE_NAME;
EOF
gcloud sql connect $SQL_INSTANCE --database=orders --user=$STUDENT_EMAIL --quiet < test_iam.sql

TIME_STAMP=$(date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/')
echo -e "   └─ ${C_GREEN}PITR Timestamp Captured: $TIME_STAMP${C_RESET}"

sleep 10
cat << 'EOF' > insert_row.sql
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
EOF

echo -e "${C_CYAN}📝 [4/5] Writing Validation Transaction to Database...${C_RESET}"
gcloud compute scp insert_row.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/insert_row.sql"

echo -e "${C_CYAN}🔄 [5/5] Executing Point-in-Time Instance Restoration...${C_RESET}"
gcloud sql instances clone $SQL_INSTANCE postgres-orders-pitr \
 --point-in-time $TIME_STAMP

echo -e "\n${C_GREEN}${C_BOLD}🏆 LAB AUTOMATION COMPLETE! CHECK YOUR PROGRESS ON QWIKLABS! 🏆${C_RESET}\n"
