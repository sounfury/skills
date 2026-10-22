#!/usr/bin/env bash
# 在远端服务器上签名并调用该机 1Panel API。Key 只存在远端 env 文件里，不经过本机。
# 用法: 1p.sh <ssh-alias> <METHOD> <PATH> [JSON]
#   1p.sh oracle GET  /api/v2/websites/list
#   1p.sh oracle POST /api/v2/websites/search '{"page":1,"pageSize":50,"name":"","websiteGroupId":0,"orderBy":"created_at","order":"descending"}'
# JSON 也可以用 @file 传本地文件: 1p.sh oracle POST /api/v2/websites @body.json
set -euo pipefail

if [[ $# -lt 3 ]]; then
  sed -n '2,7p' "$0" >&2
  exit 1
fi

host=$1 method=$2 path=$3 body=${4:-}
if [[ $body == @* ]]; then
  body=$(cat "${body#@}")
fi
b64=$(printf '%s' "$body" | base64 -w0)

ssh "$host" "M=$(printf %q "$method") P=$(printf %q "$path") B=$b64 bash -s" <<'REMOTE'
set -euo pipefail
for f in "${ONEPANEL_ENV_FILE:-}" "$HOME/.config/1panel.env" "$HOME/.codex/1panel.env"; do
  if [[ -n $f && -f $f ]]; then . "$f"; break; fi
done
if [[ -z ${ONEPANEL_BASE_URL:-} || -z ${ONEPANEL_API_KEY:-} ]]; then
  echo "1p: 远端缺少 ONEPANEL_BASE_URL / ONEPANEL_API_KEY（~/.config/1panel.env）" >&2
  exit 2
fi
ts=$(date +%s)
tok=$(printf '1panel%s%s' "$ONEPANEL_API_KEY" "$ts" | md5sum | cut -d' ' -f1)
body=$(printf '%s' "$B" | base64 -d)
args=(-sS -m "$(( ${ONEPANEL_TIMEOUT_MS:-30000} / 1000 ))" -X "$M"
  -H "1Panel-Token: $tok" -H "1Panel-Timestamp: $ts"
  -H "Content-Type: application/json" -H "Accept: application/json")
[[ ${ONEPANEL_SKIP_TLS_VERIFY:-} =~ ^(1|true|yes)$ ]] && args+=(-k)
# 面板设置了「绑定域名」时，用 127.0.0.1 访问会返回 Access Temporarily Unavailable 页面，需带上该域名作 Host
[[ -n ${ONEPANEL_HOST_HEADER:-} ]] && args+=(-H "Host: $ONEPANEL_HOST_HEADER")
[[ -n $body ]] && args+=(--data "$body")
curl "${args[@]}" "${ONEPANEL_BASE_URL%/}$P"
echo
REMOTE
