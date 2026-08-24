clear
# Colors & Visual Setup
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_TEAL='\033[38;5;38m'
C_AMBER='\033[38;5;214m'
C_GREEN='\033[38;5;82m'
C_PURPLE='\033[38;5;141m'
C_CORAL='\033[38;5;203m'

echo -e "${C_PURPLE}${C_BOLD}"
cat << "EOF"
  ┌───────────────────────────────────────────────────────────┐
  │   ⚡ CLOUD SQL POSTGRESQL LAB: STAGE 1 (VM & PROFILE)    │
  └───────────────────────────────────────────────────────────┘
EOF
echo -e "${C_RESET}"

echo -e "${C_AMBER}📌 Please enter details from your Qwiklabs instruction panel:${C_RESET}"
read -p "➔ Enter Migration user name (e.g., Postgres Migration User): " MIGRATION_USER
echo ""

echo -e "${C_TEAL}🔍 [1/5] Fetching Environment Details...${C_RESET}"
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

export VM_NAME=""
while [[ -z "$VM_NAME" ]]; do
    export VM_NAME=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep postgres)
    if [[ -z "$VM_NAME" ]]; then
        echo -e "${C_CORAL}   Waiting for target VM to initialize... (Retrying in 5s)${C_RESET}"
        sleep 5
    fi
done

export ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(zone)")
export REGION=${ZONE%-*}
export INTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].networkIP)")

echo -e "   ├─ Project ID : ${C_GREEN}$PROJECT_ID${C_RESET}"
echo -e "   ├─ Target VM   : ${C_GREEN}$VM_NAME${C_RESET}"
echo -e "   ├─ Zone / Region: ${C_GREEN}$ZONE ($REGION)${C_RESET}"
echo -e "   └─ Internal IP : ${C_GREEN}$INTERNAL_IP${C_RESET}\n"

echo -e "${C_TEAL}⚙️  [2/5] Enabling GCP APIs...${C_RESET}"
gcloud services enable datamigration.googleapis.com servicenetworking.googleapis.com --quiet

echo -e "${C_TEAL}🔑 [3/5] Testing SSH Connectivity...${C_RESET}"
while ! gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="echo 'SSH ready'"; do
    sleep 5
done

echo -e "${C_TEAL}📦 [4/5] Installing pglogical & Configuring PostgreSQL...${C_RESET}"
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="sudo apt-get update
sudo apt-get install postgresql-14-pglogical -y
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf .'
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/postgresql_append.conf .'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/pg_hba.conf || cat pg_hba_append.conf >> /etc/postgresql/14/main/pg_hba.conf'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/postgresql.conf || cat postgresql_append.conf >> /etc/postgresql/14/main/postgresql.conf'
sudo systemctl restart postgresql@14-main"

cat << EOF > sql_commands.sql
\c postgres;
CREATE EXTENSION IF NOT EXISTS pglogical;
\c orders;
CREATE EXTENSION IF NOT EXISTS pglogical;

\c postgres;
CREATE USER "${MIGRATION_USER}" PASSWORD 'DMS_1s_cool!';
ALTER DATABASE orders OWNER TO "${MIGRATION_USER}";
ALTER ROLE "${MIGRATION_USER}" WITH REPLICATION;

\c orders;
ALTER TABLE inventory_items ADD PRIMARY KEY (id);

GRANT USAGE ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.tables TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.depend TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_sync_status TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node_interface TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.queue TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_seq TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_table TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.sequence_state TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.subscription TO "${MIGRATION_USER}";

GRANT USAGE ON SCHEMA public TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA public TO "${MIGRATION_USER}";
GRANT SELECT ON public.distribution_centers TO "${MIGRATION_USER}";
GRANT SELECT ON public.inventory_items TO "${MIGRATION_USER}";
GRANT SELECT ON public.order_items TO "${MIGRATION_USER}";
GRANT SELECT ON public.products TO "${MIGRATION_USER}";
GRANT SELECT ON public.users TO "${MIGRATION_USER}";
ALTER TABLE public.distribution_centers OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.inventory_items OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.order_items OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.products OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.users OWNER TO "${MIGRATION_USER}";

\c postgres;
GRANT USAGE ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.tables TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.depend TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_sync_status TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node_interface TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.queue TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_seq TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_table TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.sequence_state TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.subscription TO "${MIGRATION_USER}";
EOF

gcloud compute scp sql_commands.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="sudo su - postgres -c 'psql -f /tmp/sql_commands.sql'"

echo -e "${C_TEAL}🌐 [5/5] Creating Database Migration Connection Profile...${RESET}"
gcloud database-migration connection-profiles create postgresql migration-profile \
    --display-name="migration-profile" \
    --region=$REGION \
    --host=$INTERNAL_IP \
    --port=5432 \
    --username="${MIGRATION_USER}" \
    --password="DMS_1s_cool!" || true

echo -e "\n${C_GREEN}${C_BOLD}✨ STAGE 1 EXECUTED SUCCESSFULLY! ✨${C_RESET}"
echo -e "${C_AMBER}👉 Next: Complete the UI Migration Job & PROMOTE step in GCP Console.${C_RESET}\n"
