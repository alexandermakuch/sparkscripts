#!/usr/bin/env bash

spark_die() {
  printf '%s: %s\n' "${SPARK_COMMAND:-spark}" "$*" >&2
  exit 1
}

spark_parse_args() {
  SPARK_EFFORT="${SPARK_EFFORT:-high}"
  SPARK_ARGS=()
  while (( $# > 0 )); do
    case "$1" in
      --effort)
        (( $# > 1 )) || spark_die "--effort requires a value"
        SPARK_EFFORT="$2"
        shift 2
        ;;
      --effort=*)
        SPARK_EFFORT="${1#*=}"
        shift
        ;;
      --)
        shift
        SPARK_ARGS+=("$@")
        break
        ;;
      *)
        SPARK_ARGS+=("$1")
        shift
        ;;
    esac
  done
  case "$SPARK_EFFORT" in
    minimal|low|medium|high|xhigh|max) ;;
    *) spark_die "invalid effort '${SPARK_EFFORT}' (use minimal, low, medium, high, xhigh, or max)" ;;
  esac
}

spark_discover() {
  command -v curl >/dev/null 2>&1 || spark_die "curl is required"
  command -v jq >/dev/null 2>&1 || spark_die "jq is required"

  [[ -n "${SPARK_ADDR:-}" ]] || spark_die "SPARK_ADDR is not set (example: export SPARK_ADDR=192.168.0.70:8888)"
  case "$SPARK_ADDR" in
    http://*|https://*) SPARK_BASE_URL="${SPARK_ADDR%/}" ;;
    *) SPARK_BASE_URL="http://${SPARK_ADDR%/}" ;;
  esac
  case "$SPARK_BASE_URL" in
    */v1) ;;
    *) SPARK_BASE_URL="${SPARK_BASE_URL}/v1" ;;
  esac

  SPARK_API_KEY="${SPARK_API_KEY:-${UNSLOTH_API_KEY:-}}"
  local curl_args=(--fail --silent --show-error --connect-timeout 5 --max-time 20)
  if [[ -n "$SPARK_API_KEY" ]]; then
    curl_args+=(--header "Authorization: Bearer ${SPARK_API_KEY}")
  fi

  local response
  response="$(curl "${curl_args[@]}" "${SPARK_BASE_URL}/models")" \
    || spark_die "could not query ${SPARK_BASE_URL}/models"
  jq -e '.data | type == "array"' >/dev/null <<<"$response" \
    || spark_die "server did not return an OpenAI-compatible model list"

  SPARK_LOADED_MODELS="$(jq -c '[.data[] | select(.loaded == true and (.id | type == "string") and (.id | length > 0))]' <<<"$response")"
  local count
  count="$(jq 'length' <<<"$SPARK_LOADED_MODELS")"
  (( count > 0 )) || spark_die "no model is loaded in Unsloth Studio at ${SPARK_ADDR}"

  if [[ -n "${SPARK_MODEL:-}" ]]; then
    jq -e --arg id "$SPARK_MODEL" 'any(.[]; .id == $id)' >/dev/null <<<"$SPARK_LOADED_MODELS" \
      || spark_die "SPARK_MODEL '${SPARK_MODEL}' is not loaded"
  else
    SPARK_MODEL="$(jq -r '.[0].id' <<<"$SPARK_LOADED_MODELS")"
  fi

  SPARK_CONTEXT="$(jq -r --arg id "$SPARK_MODEL" '.[] | select(.id == $id) | (.context_length // .native_context_length // 100000)' <<<"$SPARK_LOADED_MODELS")"
  SPARK_OUTPUT="$(jq -r --arg id "$SPARK_MODEL" '.[] | select(.id == $id) | (.max_context_length // 4096)' <<<"$SPARK_LOADED_MODELS")"
  [[ "$SPARK_CONTEXT" =~ ^[1-9][0-9]*$ ]] || SPARK_CONTEXT=100000
  [[ "$SPARK_OUTPUT" =~ ^[1-9][0-9]*$ ]] || SPARK_OUTPUT=4096

  printf '%s: using %s at %s (%s effort)\n' "$SPARK_COMMAND" "$SPARK_MODEL" "$SPARK_BASE_URL" "$SPARK_EFFORT" >&2
}
