#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/../.."

################################################################################
# This script is called by the Git post-receive hook.
################################################################################

# Run the setup script, with an environment variable to tell it we're deploying
# (so don't do anything that requires interaction like running 'sudo')
export DEPLOYING=1
scripts/setup.sh
