# pixop-cs-api-curl-demo
cURL demo of using Pixop Video Processing REST API from the Bash shell.

The following is demonstrated:

1. Authentication
1. Create new project
2. Create new video in the created project
3. Upload `small.mp4` (560x320 pixels) as media for the created video and wait for ingestion to complete
4. Trigger request to upscale video via PIXOP Super Resolution and wait for processing to complete
5. Download resultant HD 1080p media to `small_hd.mp4`
6. Delete videos and project

## Requirements
- A valid Pixop staging environment account (contact support@pixop.com)
- Bash shell
- `curl` (https://curl.haxx.se/)
- `jq` (https://stedolan.github.io/jq/)

## Initial setup

Clone repository and create personal cURL credentials file for Pixop Video Processing API:

```
    git clone https://github.com/pixop/pixop-cs-api-curl-demo
    cd pixop-cs-api-curl-demo
    cp pixop-api-netrc-template pixop-api-netrc
```

Then update the email and password in the `pixop-api-netrc`.

## Running

Run the API demo:

```
    ./pixop_api_demo.sh
```

## REST endpoints documentation

https://static.pixop.com/documentation/Pixop_Video_Processing_REST_API_staging.html
