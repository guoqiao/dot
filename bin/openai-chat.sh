#!/usr/bin/env bash

set -ueo pipefail

: "${OPENAI_BASE_URL:?env var missing}"
: "${OPENAI_API_KEY:?env var missing}"
: "${OPENAI_MODEL:?env var missing}"

if [[ -t 0 ]]; then
  # no stdin → use arg
  PROMPT="$1"
else
  # stdin provided
  PROMPT="$(cat)"
fi

JSON=$(jq -n \
  --arg model "$OPENAI_MODEL" \
  --arg content "$PROMPT" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: $content
      }
    ]
  }')

echo ${JSON} | jq | tee request.json

/usr/bin/time -p curl -fsSL ${OPENAI_BASE_URL}/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -d "${JSON}" | jq | tee response.json

echo '<think>'
jq -r '.choices[0].message.reasoning_content' response.json
echo '</think>'
echo

jq -r '.choices[0].message.content' response.json

