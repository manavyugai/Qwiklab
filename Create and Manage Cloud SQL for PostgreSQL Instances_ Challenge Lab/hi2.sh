# Lab details enter karein
read -p "➔ Enter Migrated Cloud SQL Instance ID: " SQL_INSTANCE
read -p "➔ Enter Qwiklabs Student Email: " STUDENT_EMAIL
read -p "➔ Enter Table Name (e.g., orders): " TABLE_NAME
read -p "➔ Enter PITR Retention Days (e.g., 2): " RETENTION_DAYS

export EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

# Task 3: Patch & IAM Auth
gcloud sql instances patch $SQL_INSTANCE \
    --database-flags cloudsql.iam_authentication=on \
    --authorized-networks=$EXTERNAL_IP \
    --enable-point-in-time-recovery \
    --retained-transaction-log-days=$RETENTION_DAYS \
    --quiet

gcloud sql users create $STUDENT_EMAIL \
    --instance=$SQL_INSTANCE \
    --type=CLOUD_IAM_USER --quiet || true

export SQL_IP=$(gcloud sql instances describe $SQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")

cat << EOF > iam_grant.sql
GRANT SELECT ON $TABLE_NAME TO "$STUDENT_EMAIL";
EOF

gcloud compute scp iam_grant.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/iam_grant.sql"

cat << EOF > test_iam.sql
SELECT COUNT(*) FROM $TABLE_NAME;
EOF
gcloud sql connect $SQL_INSTANCE --database=orders --user=$STUDENT_EMAIL --quiet < test_iam.sql

# Task 4: Timestamp & PITR Clone
TIME_STAMP=$(date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/')
sleep 5

cat << 'EOF' > insert_row.sql
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
EOF

gcloud compute scp insert_row.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/insert_row.sql"

gcloud sql instances clone $SQL_INSTANCE postgres-orders-pitr \
 --point-in-time $TIME_STAMP --quiet

echo -e "\n🎉 ALL TASKS (1, 2, 3 & 4) COMPLETED SUCCESSFULLY! 🎉\n"
