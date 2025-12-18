#!/usr/bin/env bash
set -euo pipefail

##############################################################################
#
#  This is a helper script for creating a summary of the daily post/blog post
#  using the OpenAI API.
#
#  (c) Steven Saus 2025
#  Licensed under the MIT license
#
##############################################################################


if [ $# -lt 1 ]; then
    echo "Usage: $0 TEXTFILE [PROMPT]" >&2
    exit 1
fi

TEXTFILE="$1"
PROMPT="${2:-Write a concise 1-3 sentence summary suitable as a WordPress blog excerpt for this roundup of interesting links and resources from the internet. Be clear and engaging but not clickbait. Output plain text only, with no markdown or HTML and no surrounding quotation marks.}"

if [ ! -f "${TEXTFILE}" ]; then
    echo "Error: '${TEXTFILE}' is not a file" >&2
    exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "Error: OPENAI_API_KEY is not set" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: 'jq' is required but not installed." >&2
    exit 1
fi

MODEL="${OPENAI_MODEL:-gpt-4.1-mini}"

# Read the text file content
CONTENT="$(cat -- "${TEXTFILE}")"

# Build the JSON request body safely with jq so all content is properly escaped
REQUEST_BODY="$(jq -n \
    --arg model "${MODEL}" \
    --arg prompt "${PROMPT}" \
    --arg content "${CONTENT}" \
    '{
        model: $model,
        messages: [
            {
                role: "system",
                content: "You write short, clean summaries of less than 150 characters to be used as WordPress blog excerpts. Do not mention the date or month.  Avoid markdown, emojis, and quotation marks; just output plain text."
            },
            {
                role: "user",
                content: ($prompt + "\n\n----\n\n" + $content)
            }
        ],
        temperature: 0.7,
        max_tokens: 150
    }'
)"

# Call OpenAI Chat Completions API
RESPONSE="$(
    curl -sS https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -d "${REQUEST_BODY}"
)"

# Extract and print just the summary text
SUMMARY="$(printf '%s\n' "${RESPONSE}" | jq -r '.choices[0].message.content // empty')"

if [ -z "${SUMMARY}" ] || [ "${SUMMARY}" = "null" ]; then
    echo "Error: No summary was returned from the API." >&2
    exit 1
fi

printf '%s\n' "${SUMMARY}"
