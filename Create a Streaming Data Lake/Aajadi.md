# Create a Streaming Data Lake on Cloud Storage: Challenge Lab || [ARC110](https://www.skills.google/course_templates/705/labs/600975) ||

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
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Create%20a%20Streaming%20Data%20Lake/15August.sh
sudo chmod +x 15August.sh
./15August.sh
```
# task4
```
# ============================================================
# TASK 4 - RUN DATAFLOW PIPELINE
# ============================================================

echo
echo -e "${BLUE}${BOLD}[TASK 4] Running Dataflow pipeline...${RESET}"

# Re-enable Dataflow API as required by the lab
gcloud services disable dataflow.googleapis.com --force --quiet 2>/dev/null || true
sleep 5

gcloud services enable dataflow.googleapis.com --quiet
sleep 15

# Create virtual environment
cd "$HOME"

python3 -m venv df-env 2>/dev/null || true
source df-env/bin/activate

# Download Google Cloud samples
if [[ ! -d "$HOME/python-docs-samples" ]]; then
    git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
fi

cd "$HOME/python-docs-samples/pubsub/streaming-analytics"

# Install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# Prevent terminal from waiting indefinitely
sed -i \
's/result.wait_until_finish()/\# result.wait_until_finish()/g' \
PubSubToGCS.py

# ------------------------------------------------------------
# Run Dataflow
# ------------------------------------------------------------

python PubSubToGCS.py \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --input_topic="projects/$PROJECT_ID/topics/$TOPIC" \
    --output_path="gs://$BUCKET/samples/output" \
    --runner=DataflowRunner \
    --window_size=2 \
    --num_shards=2 \
    --temp_location="gs://$BUCKET/temp" \
    --worker_machine_type="e2-standard-2" \
    --worker_disk_type="pd-standard"

if [[ $? -eq 0 ]]; then
    echo
    echo -e "${GREEN}${BOLD}✓ TASK 4 COMPLETED - DATAFLOW JOB SUBMITTED${RESET}"
else
    echo
    echo -e "${RED}${BOLD}✗ TASK 4 FAILED${RESET}"
    exit 1
fi

echo
echo "Wait for the Dataflow job to start and create files in:"
```
echo "gs://$BUCKET/samples/output"
echo
echo "Then click 'Check my progress'."
