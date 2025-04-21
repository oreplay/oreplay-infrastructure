#!/bin/bash
echo "hola2 $HOOK_URL"
curl --request POST \
  --url ${HOOK_URL} \
  --header 'Content-Type: application/json' \
  --data "{
  \"text\": \"DEPLOY ${PROJECT} ${CI_COMMIT_BRANCH}\",
  \"username\": \"DEPLOY ${PROJECT}\",
  \"icon_emoji\": \"${EMOJI}\",
  \"channel\": \"${CHANNEL}\",
  \"blocks\": [
    {
      \"type\": \"section\",
      \"block_id\": \"section567\",
      \"text\": {
        \"type\": \"mrkdwn\",
        \"text\": \"Deployment in progress. \n \`${CI_COMMIT_BRANCH}\`\"
      },
      \"accessory\": {
        \"type\": \"image\",
        \"image_url\": \"${IMG}\",
        \"alt_text\": \"Alt image text\"
      }
    }
  ]
  }"
