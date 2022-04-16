#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# Check if the `.env` file includes all settings from `.env.example`.
################################################################################

source 'scripts/_includes/check-dotenv.sh'

check_dotenv_against .env.example

if ! $dotenv_has_warnings; then
    green bold 'All OK'
fi
