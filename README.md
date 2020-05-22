# pixop-cs-api-curl-demo
cURL demo of driving Pixop Video Processing REST API from the Bash shell.

The following is demonstrated:

1. Authentication
1. Create new project
2. Create new video in this project
3. Upload `small.mp4` this video and wait for ingestion to complete
4. Process video and wait for processing to complete
5. Download resultant media
6. Delete videos and project

## Requirements
- a valid staging Pixop account (contact info@pixop.com)
- Bash shell
- `curl` (https://curl.haxx.se/)
- `jq` (https://stedolan.github.io/jq/)

## Initial set up

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
