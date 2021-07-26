set -euo pipefail

FAILURE="failure"
SUCCESS="success"

status=

while getopts s: options; do
  case $options in
    s) status="${OPTARG}";;
  esac
done

function slack_webhook_payload() {
  local message_header
  local message_body

  if [[ ${status} == ${SUCCESS} ]]; then
    message_header=":white_check_mark: Deploy to *${CI_ENVIRONMENT_NAME}* succeeded"
  else
    message_header=":x: Deploy to *${CI_ENVIRONMENT_NAME}* failed"
  fi

  message_body=$(cat <<-SLACK
Project: <${CI_PROJECT_URL}|${CI_PROJECT_NAME}>
Commit: <${CI_PROJECT_URL}/commit/$(git rev-parse HEAD)|$(git rev-parse --short HEAD)> - ${CI_COMMIT_REF_NAME}
Job: <${CI_PROJECT_URL}/-/jobs/${CI_JOB_ID}|${CI_JOB_ID}>
User: ${GITLAB_USER_NAME}
SLACK
)

  cat <<-SLACK
{
  "channel": "${SLACK_CHANNEL_NAME}",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "${message_header}\n${message_body}"
      }
    }
  ]
}
SLACK
}

function notify() {
  curl -X POST \
    --data-urlencode "payload=$(slack_webhook_payload)" \
    "${SLACK_WEBHOOK}"
}

notify
