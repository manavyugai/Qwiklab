# Consuming Customer Specific Datasets from Data Sharing Partners using BigQuery
**Lab Reference:** [GSP1043](https://www.cloudskillsboost.google/focuses/42015?parent=catalog)

---
## 🚀 Quick Solution Guide
Follow the steps below sequentially in their respective Google Cloud Shell environments to complete the lab setup.

### 1️⃣ Data Sharing Partner Console

Open **Cloud Shell** in the **Data Sharing Partner Project** and run:

```bash
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Consuming%20Customer/Aalu.sh
sudo chmod +x Aalu.sh
./Aalu.sh
```
### 2️⃣ Data Publisher Console
### Switch to Cloud Shell in the Data Publisher Project and run:

```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Consuming%20Customer/Piyaaj.sh
sudo chmod +x Piyaaj.sh
./Piyaaj.sh
```

### 3️⃣ Customer (Data Twin) Console
Switch to Cloud Shell in the Customer (Data Twin) Project and run:

```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Consuming%20Customer/Baigan.sh
sudo chmod +x Baigan.sh
./Baigan.sh
```

# 🎉 Congratulations!
You have successfully executed the data-sharing setup across all required project environments!
