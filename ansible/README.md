# Pixi AI Tools — SURF Research Cloud Component

Ansible playbook to deploy [Pixi](https://pixi.sh)-based AI/ML bioimage analysis tool environments on [SURF Research Cloud](https://portal.live.surfresearchcloud.nl/) workspaces.

## What it does

**At workspace creation (Ansible):**
1. Installs Pixi globally (`/usr/local/bin/pixi`)
2. Sets up a per-user [runonce](https://utrechtuniversity.github.io/researchcloud-items/roles/runonce.html) script that runs on first login
3. If JupyterHub is present, installs [pixi-kernel](https://github.com/renan-r-santos/pixi-kernel) for per-directory kernel auto-discovery and restarts JupyterHub

**At first user login (runonce):**
1. Clones [AI_tools_pixi](https://github.com/Leiden-Cell-Observatory/AI_tools_pixi) to `~/AI_tools_pixi`
2. Adds Pixi shell completion to `~/.bashrc`
3. Creates a pixi-kernel config (`~/.config/pixi-kernel/config.toml`)
4. Registers each tool as a **globally available Jupyter kernel** (e.g. "stardist (Pixi)", "cellpose (Pixi)")

**Users then:** select a tool kernel from the JupyterLab launcher — or navigate to an environment folder and use `pixi install` / `pixi shell` from the terminal. Pixi environments are installed on-demand (on first kernel start or first `pixi install`) to save disk space.

## Jupyter kernel integration

Two complementary approaches are set up automatically:

| Approach | How it works | When to use |
|----------|-------------|-------------|
| **Global kernels** (e.g. "stardist (Pixi)") | Registered per-user at first login via `kernel.json` specs that call `pixi run --manifest-path` | Select a tool from the JupyterLab launcher from **any** directory |
| **pixi-kernel** auto-discovery | Installed into JupyterHub; shows "Pixi - Python 3 (ipykernel)" | When working **inside** a `~/AI_tools_pixi/<tool>/` directory — pixi-kernel detects the `pixi.toml` automatically |

Both use `pixi run` under the hood, so the environment is only downloaded and installed the first time a kernel is actually started.

## Prerequisites

| Component | Required | Notes |
|-----------|----------|-------|
| SRC-OS (Ubuntu) | Yes | Debian-family only |
| SRC-External | Yes | Internet access for git clone + package downloads |
| Jupyter component | No | If present, pixi-kernel + global kernels are set up automatically |
| GPU flavor | No | Recommended for CUDA-accelerated tools |

## SRC Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PIXI_AI_TOOLS_VERSION` | `master` | Git branch or tag of the AI_tools_pixi repository to clone |

Set this parameter in the SRC portal when configuring the component to pin a specific release (e.g. `v0.1.0`).

## Dependencies

This playbook uses the [uusrc.general](https://github.com/UtrechtUniversity/researchcloud-items) Ansible collection for the `runonce` role. Install before running:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Usage

### Registering as an SRC catalog component

1. Create a new **plugin** in the SRC portal
2. Set the source to this repository's `ansible/pixi-ai-tools.yml` playbook
3. Optionally set the `PIXI_AI_TOOLS_VERSION` parameter
4. Add the plugin to a **catalog item** alongside SRC-OS and SRC-External
5. For JupyterLab workspaces, also include the Jupyter component — pixi-kernel integration is automatic

### Running manually (for testing)

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
ansible-playbook pixi-ai-tools.yml
```

## User workflows

### JupyterLab workspace

1. Open JupyterLab
2. Select a kernel from the launcher — e.g. **"stardist (Pixi)"** or **"CAREamics (Pixi)"**
3. The first start triggers `pixi install` and may take a few minutes to download packages
4. Subsequent kernel starts are fast

Alternatively, navigate to `~/AI_tools_pixi/cellpose/` and select the **"Pixi - Python 3 (ipykernel)"** kernel — pixi-kernel auto-detects the directory's `pixi.toml`.

### Desktop workspace

1. Open a terminal
2. Navigate to the environment: `cd ~/AI_tools_pixi/cellpose/`
3. Install dependencies: `pixi install`
4. Activate the environment: `pixi shell`
5. Or run tools directly: `pixi run python my_script.py`

### Available environments

| Environment | Description | CUDA | GPU-accelerated |
|-------------|-------------|------|-----------------|
| `biapy/` | BiaPy deep learning bioimage analysis | 12.8 | Yes |
| `CAREamics/` | Image denoising and restoration | 12.8 | Yes |
| `cellpose/` | Cell and nucleus segmentation | 12.8 | Yes |
| `micro_sam/` | Segment Anything for microscopy | 12.8 | Yes |
| `omero/` | OMERO image server client + Napari | — | No |
| `spotiflow/` | Spot detection in microscopy | 12.8 | Yes |
| `stardist/` | Star-convex object detection | 11.8 | Yes |
| `trackastra/` | Cell tracking for time-lapse data | 12.8 | Yes |

## Disk space

Each environment with PyTorch + CUDA can use **5–10 GB**. Environments are **not pre-installed** — users install only what they need. If all environments are installed, expect **~50 GB** total. Choose an appropriate VM storage size on SRC.

## Architecture

```
Ansible playbook (workspace creation)
├── Install pixi → /usr/local/bin/pixi
├── uusrc.general.runonce role → /etc/runonce.d/ mechanism
├── Deploy setup-ai-tools.sh → /etc/runonce.d/
├── [If JupyterHub] Install pixi-kernel → /etc/src/venv/src-venv/
└── [If JupyterHub] Restart JupyterHub

Per-user runonce (first login)
├── git clone AI_tools_pixi → ~/AI_tools_pixi/
├── pixi shell completion → ~/.bashrc
├── pixi-kernel config → ~/.config/pixi-kernel/config.toml
└── Register global kernels → ~/.local/share/jupyter/kernels/pixi-<tool>/

User on-demand
└── Select a kernel in JupyterLab  — or —  cd ~/AI_tools_pixi/<env>/ && pixi install
```

## Files

| File | Purpose |
|------|---------|
| `pixi-ai-tools.yml` | Main Ansible playbook |
| `requirements.yml` | Ansible collection dependencies (uusrc.general) |
| `files/setup-ai-tools.sh` | Per-user runonce script |
| `README.md` | This documentation |
