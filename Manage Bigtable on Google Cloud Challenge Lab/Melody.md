## Create and Manage Bigtable Instances: Challenge Lab



### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**


# Step 1: Initial Setup
### Run the setup script in Cloud Shell:

`````
curl -LO https://raw.githubusercontent.com/manavyugai/Qwiklab/main/Manage%20Bigtable%20on%20Google%20Cloud%20Challenge%20Lab/Melody.sh
sudo chmod +x Melody.sh
./Melody.sh
```````

# Step 2: Clean Up Resources
### Important: Verify that you have received full credit for the first 4 tasks in Qwiklabs before proceeding with the cleanup commands below.
Execute the following commands to delete the backup and instance:


```
gcloud bigtable backups delete PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1  --quiet

gcloud bigtable instances delete ecommerce-recommendations --quiet
```

### Congratulations !!!!

