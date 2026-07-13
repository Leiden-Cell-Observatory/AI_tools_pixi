#!/bin/bash
# setup-ai-tools.sh — Runonce script for per-user Pixi AI Tools setup
# Placed in /etc/runonce.d/ by the pixi-ai-tools Ansible component.
# Executed once per user upon first login (via uusrc.general.runonce).
#
# The tool environments themselves are shared and are installed system-wide by
# the Ansible playbook (/opt/AI_tools_pixi), and their Jupyter kernels are
# registered system-wide too. So this script deliberately does NOT clone the
# repo or install any environment per user — doing that once per student would
# multiply every 5-10 GB environment by the size of the class.
#
# What is left here is only the per-user cosmetics: shell completion, desktop
# launchers, and cleanup of kernels left behind by the older per-user design.

set -euo pipefail

if [ -f /etc/environment ]; then
    set -a
    # shellcheck source=/dev/null
    . /etc/environment
    set +a
fi

SHARED_DIR="${SHARED_DIR:-/opt/AI_tools_pixi}"
PIXI_CACHE_DIR="${PIXI_CACHE_DIR:-/opt/pixi-cache}"
PIXI_BIN=$(command -v pixi 2>/dev/null || echo "/usr/local/bin/pixi")
KERNEL_DIR="${HOME}/.local/share/jupyter/kernels"

if [ ! -d "${SHARED_DIR}" ]; then
    echo "Shared tools directory ${SHARED_DIR} not found — nothing to set up."
    exit 0
fi

# Older versions of this component registered per-user kernels that pointed at
# a per-user clone in ~/AI_tools_pixi. Those are superseded by the shared
# system-wide kernels, and if left in place each one would trigger a private
# multi-GB install on first use. Personal forks made with `ai-tools fork` are
# named pixi-<tool>-mine and are intentionally left alone.
for stale in "${KERNEL_DIR}"/pixi-*; do
    [ -d "${stale}" ] || continue
    case "${stale}" in *-mine) continue ;; esac
    if grep -q "${HOME}/AI_tools_pixi" "${stale}/kernel.json" 2>/dev/null; then
        echo "Removing superseded per-user kernel: $(basename "${stale}")"
        rm -rf "${stale}"
    fi
done

# Pixi shell completion + shared cache for interactive shells
if [ -f "${HOME}/.bashrc" ] && ! grep -q 'pixi completion' "${HOME}/.bashrc"; then
    echo "Adding pixi shell completion to .bashrc..."
    cat >> "${HOME}/.bashrc" << PIXI_BASHRC

# Pixi AI tools
export PIXI_CACHE_DIR="${PIXI_CACHE_DIR}"
eval "\$(pixi completion --shell bash)"
PIXI_BASHRC
fi

# pixi-kernel finds the pixi binary via this config (used when a notebook is
# opened from inside a directory that has its own pixi.toml)
PIXI_KERNEL_CONFIG_DIR="${HOME}/.config/pixi-kernel"
if [ ! -f "${PIXI_KERNEL_CONFIG_DIR}/config.toml" ] && [ -x "${PIXI_BIN}" ]; then
    echo "Creating pixi-kernel config..."
    mkdir -p "${PIXI_KERNEL_CONFIG_DIR}"
    echo "pixi-path = \"${PIXI_BIN}\"" > "${PIXI_KERNEL_CONFIG_DIR}/config.toml"
fi

# Desktop entries for GUI tools (Guacamole/VNC desktops), pointing at the
# shared environments. --frozen keeps them from trying to write to /opt.
DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "${DESKTOP_DIR}"

declare -A GUI_COMMANDS
GUI_COMMANDS[cellpose]="python -m cellpose"
GUI_COMMANDS[stardist]="napari"
GUI_COMMANDS[CAREamics]="napari"
GUI_COMMANDS[micro_sam]="napari"
GUI_COMMANDS[omero]="napari"

for tool_dir in "${SHARED_DIR}"/*/; do
    [ -f "${tool_dir}pixi.toml" ] || continue
    # Only advertise environments that were actually pre-installed
    [ -d "${tool_dir}.pixi/envs/default" ] || continue
    tool_name=$(basename "${tool_dir}")

    cat > "${DESKTOP_DIR}/pixi-${tool_name}-terminal.desktop" << DESKTOP_TERM
[Desktop Entry]
Type=Application
Name=${tool_name} (Pixi Terminal)
Comment=Open a shell in the shared ${tool_name} environment
Exec=bash -c "cd ${tool_dir} && ${PIXI_BIN} shell --frozen"
Terminal=true
Categories=Development;Science;
Icon=utilities-terminal
StartupNotify=true
DESKTOP_TERM

    if [[ -v "GUI_COMMANDS[${tool_name}]" ]]; then
        echo "Creating desktop launcher for ${tool_name}..."
        cat > "${DESKTOP_DIR}/pixi-${tool_name}.desktop" << DESKTOP_GUI
[Desktop Entry]
Type=Application
Name=${tool_name} (Pixi)
Comment=Launch the ${tool_name} graphical interface
Exec=${PIXI_BIN} run --frozen --manifest-path ${tool_dir}pixi.toml ${GUI_COMMANDS[${tool_name}]}
Terminal=false
Categories=Education;Science;
Icon=applications-science
StartupNotify=true
DESKTOP_GUI
    fi
done

if [ -d "${HOME}/Desktop" ] || [ -d "/etc/xdg/autostart" ]; then
    mkdir -p "${HOME}/Desktop"
    for desktop_file in "${DESKTOP_DIR}"/pixi-*.desktop; do
        [ -f "${desktop_file}" ] || continue
        case "${desktop_file}" in *-terminal.desktop) continue ;; esac
        cp "${desktop_file}" "${HOME}/Desktop/"
        chmod +x "${HOME}/Desktop/$(basename "${desktop_file}")"
    done
fi

echo "Pixi AI Tools setup complete. Run 'ai-tools list' to see the environments."
