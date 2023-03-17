#!/bin/sh
set -eu
IFS=$(printf "\n\t")
# scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
# atexit() {
#   rm -rf "$scratch"
# }
# trap atexit EXIT

cd "$(dirname "$0")"
if ! command -v oidc-test-client >/dev/null; then
    echo 快去下载 oidc tester！就在 https://github.com/BeryJu/oidc-test-client
    exit 1
fi

if ! lsof -i:3000 >/dev/null; then
    echo oidc 服务还没跑起来，快去跑
    exit 1
fi

export OIDC_BIND=0.0.0.0:3001
export OIDC_CLIENT_ID=23333
export OIDC_CLIENT_SECRET=Ther3IsN0Exc3pt1onInThi5Libr4ry #for i know i'll always go with you~
export OIDC_ROOT_URL="http://172.27.114.79:3001"
export OIDC_PROVIDER="http://172.27.114.79:3000"
export OIDC_SCOPES="openid,email,profile"
export OIDC_DO_REFRESH=true
export OIDC_DO_INTROSPECTION=true
export OIDC_DO_USER_INFO=true
export OIDC_TLS_VERYFI=false

oidc-test-client
