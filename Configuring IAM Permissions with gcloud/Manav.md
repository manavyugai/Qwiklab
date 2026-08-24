# 🌐 Configuring IAM Permissions with gcloud || [GSP647](https://www.skills.google/games/6670/labs/41734)

## ⚠️ Disclaimer ⚠️

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>Educational Purpose Only:</strong> This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
  <br><br>
  <strong>Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.
</blockquote>

---

<div style="padding: 15px; margin: 10px 0;">

## ☁️ Run in Cloud Shell:

```bash
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute ssh centos-clean --zone=$ZONE --quiet
```

```bash
curl -LO https://raw.githubusercontent.com/manavyugai/Qwiklab/main/Configuring%20IAM%20Permissions%20with%20gcloud/Meow.sh
sudo chmod +x Meow.sh
./Meow.sh
```
```bash
Hello
```

</div>

---

## 🎉 **Congratulations! Lab Completed Successfully!** 🏆  

