#!/bin/bash
set -o nounset -o pipefail -o errexit

################################################################################
# Run the appropriate version of PHP for this site/application.
#
# The version is determined by the `php` version constraint in `composer.json`.
################################################################################

root="$(dirname "$0")/.."
version="$(perl -ne '/"php":\s*"(\d+\.\d+)\..*"/ && print $1' "$root/composer.json")"

# shellcheck source=_includes/colors.sh
source "$root/scripts/_includes/colors.sh"

# Add cPanel system path because cron doesn't pick it up
PATH="$PATH:/usr/local/bin"

if [[ -z $version ]]; then
    yellow bold "Cannot determine the PHP version to use for this project" >&2
    black bold "Please add this to composer.json:" >&2
    echo
    black bold '    "require": {' >&2
    white bold '        "php": "7.3.*",' >&2
    black bold '        ...' >&2
    black bold '    },' >&2
    echo
    black bold "Falling back to the system default (PHP $(php -r 'echo PHP_VERSION;'))" >&2
    echo
elif ! command -v "php$version" &>/dev/null; then
    red bold "Cannot find php$version executable" >&2
    black bold "Falling back to the system default (PHP $(php -r 'echo PHP_VERSION;'))" >&2
    version=''
fi

exec "php$version" "$@"
