clear
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[38;5;51m'
C_GREEN='\033[38;5;82m'
C_AMBER='\033[38;5;214m'

echo -e "${C_CYAN}${C_BOLD}=== TASK 1: VM PREPARATION & DATABASE SETUP ===${C_RESET}\n"

# 1. Inputs Prompt
read -p "➔ Enter Migration User Name from Lab (e.g. Postgres Migration User or migration_admin): " MIGRATION_USER
echo ""

# 2. Environment Variables
export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
export VM_NAME=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep postgres)
export ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(zone)")
export REGION=${ZONE%-*}
export INTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].networkIP)")

# 3. Enable Google APIs
echo -e "${C_AMBER}Enabling APIs...${C_RESET}"
gcloud services enable datamigration.googleapis.com servicenetworking.googleapis.com --quiet

# 4. Install pglogical & configuration on VM
echo -e "${C_AMBER}Configuring PostgreSQL and pglogical extension on VM...${C_RESET}"
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="
sudo apt-get update && sudo apt-get install postgresql-14-pglogical -y
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf .'
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/postgresql_append.conf .'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/pg_hba.conf || cat pg_hba_append.conf >> /etc/postgresql/14/main/pg_hba.conf'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/postgresql.conf || cat postgresql_append.conf >> /etc/postgresql/14/main/postgresql.conf'
sudo systemctl restart postgresql@14-main
"

# 5. SQL Script generation for User, Permissions & Primary Keys
cat << EOF > sql_commands.sql
\c postgres;
CREATE EXTENSION IF NOT EXISTS pglogical;
\c orders;
CREATE EXTENSION IF NOT EXISTS pglogical;

\c postgres;
CREATE USER "${MIGRATION_USER}" WITH PASSWORD 'DMS_1s_cool!';
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

# 6. Apply SQL Commands
echo -e "${C_AMBER}Applying privileges and primary keys...${C_RESET}"
gcloud compute scp sql_commands.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="sudo su - postgres -c 'psql -f /tmp/sql_commands.sql'"

echo -e "\n${C_GREEN}${C_BOLD}✅ TASK 1 PREPARATION COMPLETED!${C_RESET}\n"
