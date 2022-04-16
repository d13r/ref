#!/bin/bash
set -o nounset -o pipefail -o errexit
cd "$(dirname "$0")/../.."

################################################################################
# Install the Git hooks required for the deploy scripts to work.
#
# Run this on the staging and live sites.
################################################################################

# To reverse this script:
# rm .git/hooks/pre-receive .git/hooks/post-receive
# git config --unset receive.denyCurrentBranch

# To test it:
# WARNING: This will call "git reset --hard" and lose all local changes!
#   echo "X X $(git symbolic-ref HEAD)" | .git/hooks/pre-receive
#   echo "X X $(git symbolic-ref HEAD)" | .git/hooks/post-receive

#---------------------------------------
# Pre-receive hook
#---------------------------------------

echo "Creating .git/hooks/pre-receive..."

cat <<'END' > .git/hooks/pre-receive
#!/bin/bash

# If the script has been called as a hook, chdir to the working copy
if [ "$GIT_DIR" = "." ]; then
    cd ..
    GIT_DIR=.git
    export GIT_DIR
fi

# Try to obtain the usual system PATH
if [ -f /etc/profile ]; then
    PATH=$(source /etc/profile; echo $PATH)
    export PATH
fi

# Check for local changes to working copy or stage, including untracked files
if [ -n "$(git status --porcelain)" ]; then
    echo >&2 "========================================================================"
    echo >&2 "Error: The remote has uncommitted changes."
    echo >&2 "========================================================================"
    exit 1
fi
END


#---------------------------------------
# Post-receive hook
#---------------------------------------

echo "Creating .git/hooks/post-receive..."

cat <<'END' > .git/hooks/post-receive
#!/bin/bash

# Use this separator to make it more noticable in the output on the remote site
# It is 72 chars wide because the prefix "remote: " is 8 chars wide
draw_line() {
    echo "========================================================================"
}

draw_line

# If the script has been called as a hook, chdir to the working copy
if [ "$GIT_DIR" = "." ]; then
    cd ..
    export GIT_DIR=".git"
fi

# Try to obtain the usual system PATH
if [ -f /etc/profile ]; then
    export PATH="$(source /etc/profile; echo $PATH)"
fi

# Get the current branch
head="$(git symbolic-ref HEAD)"

# Abort if we're on a detached head
if [ "$?" != "0" ]; then
    echo "Remote is in 'detached HEAD' state, skipping push hook."
    draw_line
    exit
fi

# Read the STDIN to detect if this push changed the current branch
while read oldrev newrev refname; do
    [ "$refname" = "$head" ] && break
done

# Abort if there's no update, or in case the branch is deleted
if [ -z "${newrev//0}" ]; then
    echo "No updates to checked out '$(git symbolic-ref --short HEAD)' branch, skipping push hook."
    draw_line
    exit
fi

# Check out the latest code into the working copy
echo -e "\e[34;1mUpdating working copy...\e[0m"

if [[ -d /var/cpanel ]]; then
    umask 022
else
    umask 007
fi

git reset --hard

# Run the after-deploy script (which may have been updated above)
if [ -f scripts/deploy/_after-deploy.sh ]; then
    scripts/deploy/_after-deploy.sh
fi

draw_line
END

#---------------------------------------
# Configure Git
#---------------------------------------

# Make hooks executable so they are run
echo "Making hooks executable..."
chmod +x .git/hooks/pre-receive .git/hooks/post-receive

# Allow pushes to the checked out branch
echo "Configuring Git..."
git config receive.denyCurrentBranch ignore

echo "All done."
