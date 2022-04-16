#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/.."

################################################################################
# Set file permissions correctly for the development server.
################################################################################

if [[ ${DEPLOYING:-} = 1 ]]; then
    deploying=true
else
    deploying=false
fi

maybe_suppress_errors() {
    if $deploying; then
        eval "$@" 2>/dev/null || true
    else
        eval "$@"
    fi
}

if [[ $PWD = /home/www/*/repo ]]; then
    # Update the config and log files as well
    root=..
else
    root=.
fi

# Ownership
if ! $deploying; then
    echo "Taking ownership of files..."
    if grep -q "^www:" /etc/group; then
        group='www'
    else
        group=$USER
    fi
    sudo chown -R $USER:$group $root
fi

# Permissions
echo "Setting permissions..."
maybe_suppress_errors chmod ug+rwX,o-rwx -R $root

# Make sure the scripts are all executable
maybe_suppress_errors chmod +x -R scripts

# Group sticky (new files owned by 'www' group instead of the current user)
echo "Setting sticky bit on directories..."
maybe_suppress_errors find $root -type d -exec chmod g+s '{}' +

echo "Done."
