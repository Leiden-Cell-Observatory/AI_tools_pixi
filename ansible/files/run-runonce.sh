#!/bin/bash
# run-runonce.sh — Execute /etc/runonce.d scripts for the current user.
# Replicates the logic of /etc/profile.d/runonce.sh but without requiring
# an interactive login shell.  Called by the JupyterHub pre_spawn_hook so
# that per-user setup (git clone, kernel registration, etc.) happens even
# when a user logs in directly to JupyterLab without opening a terminal.

set -euo pipefail

# Source /etc/environment for variables set by Ansible (e.g. PIXI_AI_TOOLS_VERSION)
if [ -f /etc/environment ]; then
    set -a
    # shellcheck source=/dev/null
    . /etc/environment
    set +a
fi

# Guard: only run if the runonce symlink exists (same check as runonce.sh)
if [ -h ~/runonce.d ] && [ -d /etc/runonce.d ]; then
    date > ~/.runonce.log
    for i in $(find -L ~/runonce.d -type f -executable -print | sort); do
        echo "--- Runonce (pre-spawn): executing $i" >> ~/.runonce.log 2>&1
        bash "$i" >> ~/.runonce.log 2>&1 || \
            echo "Warning: error occurred in $i. See .runonce.log." >> ~/.runonce.log 2>&1
    done
    rm ~/runonce.d
fi
