#!/usr/bin/env bash
# Source this file to get a fresh GitHub App installation token in GH_TOKEN:
#
#     . "$(dirname ...)/github-app-env.sh" && gh api /installation/repositories
#
# Mints only when the cached token is within 5 minutes of expiry, so it is
# cheap to call before every command. The token is never printed.
#
# Resolution order for the minter:
#   1. $GH_APP_TOKEN_CMD
#   2. `github-app-token` on PATH (the packaged wrapper)
#   3. $GH_APP_TOKEN_SCRIPT, or github-app-token.py beside this file, run with
#      ${HERMES_PYTHON:-python3} — that interpreter must provide `cryptography`

if [ -n "${GH_APP_TOKEN_CMD:-}" ]; then
  _gh_app_token() { $GH_APP_TOKEN_CMD "$@"; }
elif command -v github-app-token >/dev/null 2>&1; then
  _gh_app_token() { github-app-token "$@"; }
else
  _gh_app_script="${GH_APP_TOKEN_SCRIPT:-$(dirname "${BASH_SOURCE[0]}")/github-app-token.py}"
  if [ ! -f "${_gh_app_script}" ]; then
    echo "github-app-env: no minter found (set GH_APP_TOKEN_CMD or GH_APP_TOKEN_SCRIPT)" >&2
    unset -f _gh_app_token 2>/dev/null
    return 1 2>/dev/null || exit 1
  fi
  _gh_app_token() { "${HERMES_PYTHON:-python3}" "$_gh_app_script" "$@"; }
fi

GH_TOKEN="$(_gh_app_token)" || {
  unset GH_TOKEN _gh_app_token
  return 1 2>/dev/null || exit 1
}
export GH_TOKEN

# Let git use the token for github.com over HTTPS without embedding it in a
# remote URL — an embedded token rots within the hour and fails confusingly
# later. Set through GIT_CONFIG_* so no global git config is mutated.
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=credential.https://github.com.helper
export GIT_CONFIG_VALUE_0='!gh auth git-credential'

unset -f _gh_app_token
