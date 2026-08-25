## Monitoring in Google Cloud: Challenge Lab

<blockquote style="background-color: #1e1e2e; color: #cdd6f4; border-left: 5px solid #89b4fa; border-radius: 8px; padding: 1.2em; font-family: sans-serif; font-size: 14px; line-height: 1.6; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
  <div style="color: #89b4fa; font-weight: bold; font-size: 16px; margin-bottom: 8px;">
    ℹ️ DISCLAIMER
  </div>
  <strong style="color: #f9e2af;">Educational Purpose Only:</strong> This script and guide are provided for educational purposes to help you understand lab services and boost your career. Please review the script before use to familiarize yourself with Google Cloud services.
  <br><br>
  <strong style="color: #f9e2af;">Terms Compliance:</strong> Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The goal is to enhance your learning experience — not to circumvent it.
</blockquote>




### Run the following Commands in CloudShell

```
curl -LO https://raw.githubusercontent.com/manavyugai/Qwiklab/main/Monitoring%20in%20Google%20Cloud_%20Challenge%20Lab/Prince.sh
sudo chmod +x Prince.sh
./Prince.sh
```
* Go to `Create log-based metric` from [here](https://console.cloud.google.com/logs/metrics/edit?)

1. For 

2. Paste The Following in vm (cloud shell)
```
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

3. Paste The Following in `Regular Expression` field:
```
# Configures Ops Agent to collect telemetry from the app and restart Ops Agent.

set -e

# Create a back up of the existing file so existing configurations are not lost.
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak

# Configure the Ops Agent.
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache
logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
EOF

sudo service google-cloud-ops-agent restart
sleep 60
```


</div>
