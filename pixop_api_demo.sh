#!/usr/bin/env bash

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

API_SITE=https://staging-api.pixop.com

ACCOUNTS_PATH=$API_SITE/accounts/v1
VIDEOS_PATH=$API_SITE/videos/v1
MEDIA_PATH=$API_SITE/media/v1

CURL_COMMON_HEADERS='-H "Content-Type: application/json" -H "Accept: application/json"'

### Step 1: Fetch JWT auth token
echo "Step #1: Authenticating..."

AUTH_RESPONSE=$(eval "curl -s -f --netrc-file pixop-api-netrc $CURL_COMMON_HEADERS $ACCOUNTS_PATH/token")

if [ $? -ne 0 ]; then
  echo
  echo 'Error: failed to fetch JWT token. Possible reasons: invalid credentials provided (check pixop-api-netrc) or service is unavailable.' >&2
  exit 1
fi

echo
echo "Auth token response..."
echo $AUTH_RESPONSE | jq

# Parse JWT token
JWT_TOKEN=$(echo $AUTH_RESPONSE | jq -r '.jwtToken')

echo "Parsed JWT token: $JWT_TOKEN"

# Prepare cURL headers
CURL_AUTH_HEADER="-H \"Authorization: Bearer $JWT_TOKEN\""
CURL_ALL_HEADERS="$CURL_COMMON_HEADERS $CURL_AUTH_HEADER"


### Step 2: Create new project
echo
echo "Step #2: Creating new project..."

PROJECT_RESPONSE=$(eval "curl -s -X PUT $CURL_ALL_HEADERS -d '{\"name\": \"Demo project\"}' $VIDEOS_PATH/project")

echo
echo "Create new project response..."
echo $PROJECT_RESPONSE | jq

# Parse project id
PROJECT_ID=$(echo $PROJECT_RESPONSE | jq -r '.project.id')
echo "Parsed new project id: $PROJECT_ID"


### Step 3: Create new video into the previously created project
echo
echo "Step #3: Creating new video..."

VIDEO_RESPONSE=$(eval "curl -s -X PUT $CURL_ALL_HEADERS -d '{\"projectId\": \"$PROJECT_ID\"}' $VIDEOS_PATH/video")

echo
echo "Create new video response..."
echo $VIDEO_RESPONSE | jq

# Parse video id nand upload endpoint
VIDEO_ID=$(echo $VIDEO_RESPONSE | jq -r '.videoId')
UPLOAD_ENDPOINT=$(echo $VIDEO_RESPONSE | jq -r '.uploadLightMediaUrl')

echo "Parsed new video id: $VIDEO_ID"
echo "Parsed upload light ingested endpoint: $UPLOAD_ENDPOINT"


### Step 4: Upload media
echo
echo "Step #4: Uploading media file into video entity..."

UPLOAD_RESPONSE=$(eval "curl -s -F file=@small.mov $CURL_AUTH_HEADER $UPLOAD_ENDPOINT")

echo
echo "Upload media response..."
echo $UPLOAD_RESPONSE | jq

# Parse check ingest progress endpoint and process endpoint
CHECK_INGEST_PROGRESS_ENDPOINT=$(echo $UPLOAD_RESPONSE | jq -r '.checkIngestProgressUrl')
PROCESS_VIDEO_ENDPOINT=$(echo $UPLOAD_RESPONSE | jq -r '.processVideoUrl')

echo "Parsed check ingest progress endpoint: $CHECK_INGEST_PROGRESS_ENDPOINT"
echo "Parsed process video endpoint: $PROCESS_VIDEO_ENDPOINT"


### Step 5: Wait for light ingestion to complete
echo
echo "Step #5: Waiting for ingestion to complete (this might take up to 15 seconds)..."
echo

sleep 5

while [ $(eval "curl -s $CURL_ALL_HEADERS $CHECK_INGEST_PROGRESS_ENDPOINT" | jq -r '.ingestionState.ingestionStatus') != "DONE" ]
do
  sleep 5
  echo Still waiting...
done


### Step 6: Upscale video to HD 1080p
echo
echo "Step #6: Triggering a process video request..."

PROCESS_REQUEST_BODY='{
  "scaler": "pabsr1",
  "resolution": {
    "tag": "hd_1080p"
  },
  "clarityBoost": "medium"
}'
PROCESS_RESPONSE=$(eval "curl -s $CURL_ALL_HEADERS -d '$PROCESS_REQUEST_BODY' $PROCESS_VIDEO_ENDPOINT")

echo
echo "Process video response..."
echo $PROCESS_RESPONSE | jq

# Parse check progress and download URLs
CHECK_PROGRESS_ENDPOINT=$(echo $PROCESS_RESPONSE | jq -r '.checkProgressUrl')
DOWNLOAD_ENDPOINT=$(echo $PROCESS_RESPONSE | jq -r '.downloadMediaUrl')

echo "Parsed check progress endpoint: $CHECK_PROGRESS_ENDPOINT"
echo "Parsed download media endpoint: $DOWNLOAD_ENDPOINT"


### Step 7: Wait for processing to complete
echo
echo "Step #7: Waiting for processing to complete (note: this can take from 15 seconds up to several minutes depending on whether compute infrastructure is available)..."
echo

sleep 5

while [ $(eval "curl -s $CURL_ALL_HEADERS $CHECK_PROGRESS_ENDPOINT" | jq -r '.processingState.processingStatus') != "DONE" ]
do
  sleep 10
  echo Still waiting...
done


### Step 8: Download processed media
echo
echo "Step #8: Downloading processed media..."

DOWNLOAD_RESPONSE=$(eval "curl -s $CURL_AUTH_HEADER $DOWNLOAD_ENDPOINT -o small_hd.mov")

echo
echo "Download media response (no output if no errors occurred)..."
echo $DOWNLOAD_RESPONSE | jq


### Step 9: Delete original and processed videos
echo
echo "Step #9: Deleting original and processed videos..."

DELETE_VIDEO_RESPONSE=$(eval "curl -s -X DELETE $CURL_ALL_HEADERS $VIDEOS_PATH/video/$VIDEO_ID")

echo
echo "Delete videos response..."
echo $DELETE_VIDEO_RESPONSE | jq


### Step 10: Delete project
echo
echo "Step #10: Deleting project..."

DELETE_VIDEO_RESPONSE=$(eval "curl -s -X DELETE $CURL_ALL_HEADERS $VIDEOS_PATH/project/$PROJECT_ID")

echo
echo "Delete project response (no output if no errors occurred)..."
echo $DELETE_PROJECT_RESPONSE | jq


### Print original and processed file size
echo
echo "Original file 'small.mov' (560x320 pixels):       $(wc -c < small.mov) bytes"
echo "Processed file 'small_hd.mov' (1890x1080 pixels): $(wc -c < small_hd.mov) bytes"

### All done!
echo
echo "All done. Have a nice day!"
