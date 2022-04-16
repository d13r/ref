#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# Create files & directories, and install/update dependencies.
################################################################################

source scripts/_includes/colors.sh

# Header
header() {
    echo
    blue bold "$1"
}

# Check if the site has already been configured
if [[ -f .env ]]; then
    envExists=true
else
    envExists=false
fi

# Create files & directories
create_dir() {
    dir="$1"

    if [[ -d "$dir" ]]; then
        echo "'$dir/' already exists"
    else
        echo "Creating directory '$dir/'"
        mkdir -p "$dir"
    fi
}

create_file() {
    dest="$1"
    src="${2:-$1.example}"

    if [[ -f "$dest" ]]; then
        echo "'$dest' already exists"
    else
        echo "Copying '$src' to '$dest'"
        cp $src $dest
    fi
}

create_symlink() {
    link="$1"
    target="$2"

    if [[ -L "$link" ]]; then
        echo "'$link' already exists"
    else
        echo "Creating '$link' symlink to '$target'"
        ln -s "$target" "$link"
    fi
}

header "Creating files & directories..."
create_file .env
#create_file www/.htaccess

# Bail now if .env is not already configured
if ! $envExists; then
    echo
    red bold "Please configure .env then run setup again"
    exit 1 # Error code in case any other scripts (e.g. deploy) depend on this
fi

# Check .env is up-to-date
header "Checking .env file is up-to-date..."
if [[ ${DEPLOYING:-} = 1 ]]; then
    # Don't exit if deploying because they may be minor changes that don't affect the rest of the script
    scripts/check-dotenv.sh || true
else
    scripts/check-dotenv.sh
fi

# Determine the environment / mode
if [[ -f .env ]]; then
    source .env
fi

if [[ ${APP_ENV:-} = "local" ]]; then
    devMode=true
else
    devMode=false
fi

# Composer
if [[ -f composer.json ]]; then
    header 'Installing Composer (PHP) packages...'

    if $devMode; then
        scripts/composer.sh install --no-interaction --ansi
    else
        scripts/composer.sh install --no-interaction --ansi --no-dev --classmap-authoritative
    fi
fi

# File permissions
header 'Updating file permissions...'

if $devMode; then
    scripts/permissions-for-development.sh
else
    scripts/permissions-for-live.sh
fi
