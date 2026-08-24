# Create and Manage Cloud SQL for PostgreSQL Instances: Challenge Lab [GSP355](https://www.skills.google/course_templates/652/labs/613053)
<blockquote style="background-color: #1e1e2e; color: #cdd6f4; border-left: 5px solid #89b4fa; border-radius: 8px; padding: 1.2em; font-family: sans-serif; font-size: 14px; line-height: 1.6; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
  <div style="color: #89b4fa; font-weight: bold; font-size: 16px; margin-bottom: 8px;">
    ℹ️ DISCLAIMER
  </div>
  <strong style="color: #f9e2af;">Educational Purpose Only:</strong> This script and guide are provided for educational purposes to help you understand lab services and boost your career. Please review the script before use to familiarize yourself with Google Cloud services.
  <br><br>
  <strong style="color: #f9e2af;">Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The goal is to enhance your learning experience — not to circumvent it.
</blockquote>

## Step 1: VM ke andar PostgreSQL aur Primary Keys set karein
```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Create%20and%20Manage%20Cloud%20SQL%20for%20PostgreSQL%20Instances%3A%20Challenge%20Lab/Hanuman1.sh
sudo chmod +x Hanuman1.sh
./Hanuman1.sh
```
## 🔹 Step 2: Google Console GUI Steps (Short)

Database Migration > Migration Jobs > Create Migration Job.
Details: Name = migration-job, Type = Continuous, Source = PostgreSQL, Destination = Cloud SQL for PostgreSQL.
Source: migration-profile select karein.
Destination: Apni lab instructions se Migrated Cloud SQL for PostgreSQL Instance ID chunen. Password me supersecret! enter karein.
Connectivity: VPC Peering > Network = default > Allocate & Connect.
Create & Start Job kar ke status Running (CDC) aane ka wait karein.
Job khol kar PROMOTE par click kar dein aur Completed hone ka wait karein.
Qwiklabs me Check My Progress (Task 1 & Task 2) click karein.

## 🚀 Command 2 of 2 (IAM Auth & PITR Recovery)
(Migration Job Promote ho jane ke baad ise chalayein)
```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Create%20and%20Manage%20Cloud%20SQL%20for%20PostgreSQL%20Instances%3A%20Challenge%20Lab/Hanuman2.sh
sudo chmod +x Hanuman2.sh
./Hanuman2.sh
```
# BHARAT MATA KI JAI!
```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Create%20and%20Manage%20Cloud%20SQL%20for%20PostgreSQL%20Instances%3A%20Challenge%20Lab/Auto.sh
sudo chmod +x Auto.sh
./Auto.sh
```
