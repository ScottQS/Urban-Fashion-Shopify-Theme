#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND="${1:-}"

load_env() {
  if [[ -f "${ROOT_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    source "${ROOT_DIR}/.env"
  fi
}

require_node_modules() {
  if [[ ! -d "${ROOT_DIR}/node_modules" ]]; then
    echo "Dependencies are not installed yet."
    echo "Run: npm install"
    exit 1
  fi
}

run_shopify() {
  require_node_modules
  npx --no-install shopify "$@"
}

require_store() {
  if [[ -z "${SHOPIFY_STORE:-}" ]]; then
    echo "Missing SHOPIFY_STORE in .env."
    echo "Example: SHOPIFY_STORE=your-store.myshopify.com"
    exit 1
  fi
}

append_theme_id_flag() {
  local -n args_ref=$1
  if [[ -n "${SHOPIFY_THEME_ID:-}" ]]; then
    args_ref+=(--theme "${SHOPIFY_THEME_ID}")
  fi
}

print_usage() {
  cat <<'EOF'
Usage:
  npm run setup             # create .env from .env.example
  npm run login             # authenticate Shopify CLI to your store
  npm run dev               # run local development server
  npm run pull              # pull the remote theme to local files
  npm run push              # push local changes to the remote theme
  npm run check             # run Shopify theme checks
  npm run version:shopify   # print Shopify CLI version
  npm run shopify -- <...>  # run any raw Shopify CLI command
EOF
}

if [[ -z "${COMMAND}" ]]; then
  print_usage
  exit 1
fi

shift || true

case "${COMMAND}" in
  setup)
    if [[ -f "${ROOT_DIR}/.env" ]]; then
      echo ".env already exists."
      exit 0
    fi

    cp "${ROOT_DIR}/.env.example" "${ROOT_DIR}/.env"
    echo "Created .env from .env.example."
    echo "Update SHOPIFY_STORE (and optionally SHOPIFY_THEME_ID), then run:"
    echo "  npm run login"
    echo "  npm run dev"
    ;;

  login)
    load_env
    require_store
    run_shopify auth login --store "${SHOPIFY_STORE}" "$@"
    ;;

  dev)
    load_env
    require_store
    args=(theme dev --store "${SHOPIFY_STORE}")
    append_theme_id_flag args
    run_shopify "${args[@]}" "$@"
    ;;

  pull)
    load_env
    require_store
    args=(theme pull --store "${SHOPIFY_STORE}")
    append_theme_id_flag args
    run_shopify "${args[@]}" "$@"
    ;;

  push)
    load_env
    require_store
    args=(theme push --store "${SHOPIFY_STORE}")
    append_theme_id_flag args
    run_shopify "${args[@]}" "$@"
    ;;

  check)
    run_shopify theme check "$@"
    ;;

  version)
    run_shopify version "$@"
    ;;

  raw)
    load_env
    if [[ $# -eq 0 ]]; then
      echo "Provide a Shopify CLI command after '--'."
      echo "Example: npm run shopify -- theme list --store your-store.myshopify.com"
      exit 1
    fi
    run_shopify "$@"
    ;;

  *)
    echo "Unknown command: ${COMMAND}"
    print_usage
    exit 1
    ;;
esac
