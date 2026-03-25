#!/bin/bash
# setup-ai-tools.sh — Runonce script for per-user Pixi AI Tools setup
# Placed in /etc/runonce.d/ by the pixi-ai-tools Ansible component.
# Executed once per user upon first login (via uusrc.general.runonce).

set -euo pipefail

# Source /etc/environment to pick up PIXI_AI_TOOLS_VERSION set by the playbook
# (may not be in the environment yet if this is the user's first login)
if [ -f /etc/environment ]; then
    set -a
    # shellcheck source=/dev/null
    . /etc/environment
    set +a
fi

REPO_URL="https://github.com/Leiden-Cell-Observatory/AI_tools_pixi.git"
INSTALL_DIR="${HOME}/AI_tools_pixi"
PIXI_AI_TOOLS_VERSION="${PIXI_AI_TOOLS_VERSION:-master}"

# Clone the AI tools repository if not already present
if [ ! -d "${INSTALL_DIR}" ]; then
    echo "Cloning AI_tools_pixi (${PIXI_AI_TOOLS_VERSION}) to ${INSTALL_DIR}..."
    git clone --branch "${PIXI_AI_TOOLS_VERSION}" --depth 1 \
        "${REPO_URL}" "${INSTALL_DIR}"
else
    echo "AI_tools_pixi already exists at ${INSTALL_DIR}, skipping clone."
fi

# Add pixi shell completion to .bashrc if not already present
if [ -f "${HOME}/.bashrc" ] && ! grep -q 'pixi completion' "${HOME}/.bashrc"; then
    echo "Adding pixi shell completion to .bashrc..."
    cat >> "${HOME}/.bashrc" << 'PIXI_COMPLETION'

# Pixi shell completion
eval "$(pixi completion --shell bash)"
PIXI_COMPLETION
fi

# Create pixi-kernel config so it can find the pixi binary
PIXI_KERNEL_CONFIG_DIR="${HOME}/.config/pixi-kernel"
PIXI_KERNEL_CONFIG="${PIXI_KERNEL_CONFIG_DIR}/config.toml"
if [ ! -f "${PIXI_KERNEL_CONFIG}" ]; then
    PIXI_BIN=$(command -v pixi 2>/dev/null || echo "/usr/local/bin/pixi")
    if [ -x "${PIXI_BIN}" ]; then
        echo "Creating pixi-kernel config at ${PIXI_KERNEL_CONFIG}..."
        mkdir -p "${PIXI_KERNEL_CONFIG_DIR}"
        echo "pixi-path = \"${PIXI_BIN}\"" > "${PIXI_KERNEL_CONFIG}"
    fi
fi

# Register each pixi environment as a globally available Jupyter kernel.
# This creates kernel specs that use "pixi run" as the launcher, so the
# actual environment is only installed on first kernel start (not now).
KERNEL_BASE_DIR="${HOME}/.local/share/jupyter/kernels"
PIXI_BIN=$(command -v pixi 2>/dev/null || echo "/usr/local/bin/pixi")

for tool_dir in "${INSTALL_DIR}"/*/; do
    [ -f "${tool_dir}/pixi.toml" ] || continue
    # Only register tools that have jupyter or ipykernel as a dependency
    grep -qE 'jupyter|ipykernel' "${tool_dir}/pixi.toml" || continue

    tool_name=$(basename "${tool_dir}")
    kernel_dir="${KERNEL_BASE_DIR}/pixi-${tool_name}"

    if [ ! -d "${kernel_dir}" ]; then
        echo "Registering Jupyter kernel for ${tool_name}..."
        mkdir -p "${kernel_dir}"
        cat > "${kernel_dir}/kernel.json" << KERNEL_JSON
{
  "argv": [
    "${PIXI_BIN}",
    "run",
    "--manifest-path", "${tool_dir}pixi.toml",
    "python", "-m", "ipykernel_launcher",
    "-f", "{connection_file}"
  ],
  "display_name": "${tool_name} (Pixi)",
  "language": "python"
}
KERNEL_JSON
    fi
done

echo "Pixi AI Tools setup complete."
