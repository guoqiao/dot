#!/usr/bin/env bash

set -ueo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <audio-file>" >&2
  exit 1
fi

if [[ ! -f "$1" || ! -r "$1" ]]; then
  echo "Error: not a readable audio file: $1" >&2
  exit 1
fi

: "${OPENAI_BASE_URL:?env var missing}"
: "${OPENAI_API_KEY:?env var missing}"
: "${OPENAI_ASR_MODEL:?env var missing}"

audio="$1"
tmpdir=
trap 'if [[ -n ${tmpdir:-} ]]; then rm -rf -- "${tmpdir}"; fi' EXIT

# Convert non-WAV audio to normalized, mono 16 kHz WAV.
audio_ext="${audio##*.}"
if [[ "${audio_ext,,}" != "wav" ]]; then
  tmpdir=$(mktemp -d)
  audio_wav="${tmpdir}/audio.wav"
  ffmpeg -y -loglevel error -i "${audio}" -vn -ac 1 -ar 16000 -af loudnorm -c:a pcm_s16le "${audio_wav}"
  audio="${audio_wav}"
fi

curl -fsSL "${OPENAI_BASE_URL%/}/audio/transcriptions" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -F "file=@${audio}" \
  --form-string "model=${OPENAI_ASR_MODEL}" \
  | jq -er '.text // error("response did not contain transcript text")'
