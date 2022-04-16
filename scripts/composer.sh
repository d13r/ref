#!/bin/bash
set -o nounset -o pipefail -o errexit

################################################################################
# Run the appropriate version of Composer for this site/application.
#
# The version is determined by the `php` version constraint in `composer.json`.
################################################################################

root="$(dirname "$0")/.."

if ! composer="$(command -v composer 2>/dev/null)"; then
    # shellcheck source=_includes/colors.sh
    source "$root/scripts/_includes/colors.sh"
    red bold "Cannot find composer executable" >&2
    exit 127
fi

exec "$root/scripts/php.sh" "$composer" "$@"
