# Pixi AI Tools — SURF Research Cloud Component

Ansible playbook to deploy [Pixi](https://pixi.sh)-based AI/ML bioimage analysis tool environments on [SURF Research Cloud](https://portal.live.surfresearchcloud.nl/) workspaces, designed for teaching workspaces where many students share one VM.

## What it does

**At workspace creation (Ansible):**
1. Installs Pixi globally (`/usr/local/bin/pixi`)
2. Clones the tools **once** to `/opt/AI_tools_pixi` (root-owned, read-only for users)
3. Pre-installs the environments named by `PIXI_AI_TOOLS_PRELOAD` into that shared location
4. Registers a **system-wide Jupyter kernel** per pre-installed tool — every user sees them at first login, with no per-user setup
5. Sets up a **shared package cache** at `/opt/pixi-cache` that users can write to
6. Installs `pixi-kernel` into the JupyterHub single-user venv and lifts SRC's kernel allowlist (see below)

**At first user login (runonce):** shell completion, desktop launchers for GUI tools, and cleanup of kernels left by older versions. No cloning, no environment installs.

## Two SRC-specific gotchas this component handles

SURF's Jupyter component restricts the JupyterLab launcher to a single kernel:

```python
c.Spawner.args = ["--KernelSpecManager.ensure_native_kernel=False",
                  "--KernelSpecManager.whitelist={'src-default'}"]
```

Any kernel you register is discovered and then **silently filtered out of the launcher**. The playbook appends its own `c.Spawner.args` to `/etc/jupyterhub/jupyterhub_config.py` (last assignment wins) to remove that allowlist.

SRC also ships **two** venvs. `/etc/src/venv/src-venv` is the tooling venv; the single-user notebook servers are spawned from `/etc/src/venv/jupyter-venv`. Anything installed into the wrong one is invisible to Jupyter. The playbook locates the venv that actually owns `jupyterhub-singleuser` rather than assuming a name.

## Why the environments are shared

A per-user copy of every environment does not fit on a teaching VM: each env with PyTorch + CUDA is 5–10 GB, and a per-user package cache duplicates the downloads on top of that. A class of 20 would need multiple terabytes.

Instead there is one root-owned copy in `/opt/AI_tools_pixi` and one shared cache. Kernels run it with `pixi run --frozen`, which uses the lock file as-is: no solve, no writes to `/opt`, and the kernel starts in seconds instead of timing out behind a multi-GB install.

Users cannot write to `/opt`, so **only pre-installed tools get a shared kernel.**

## Adding packages: `ai-tools`

Students who need extra packages fork an environment into their home directory:

```bash
ai-tools list            # what is available, and what you have your own copy of
ai-tools fork cellpose   # your own editable copy in ~/AI_tools_pixi/cellpose
cd ~/AI_tools_pixi/cellpose && pixi add scikit-image
ai-tools reset cellpose  # throw your copy away, go back to the shared one
```

A fork copies only `pixi.toml` + `pixi.lock` and reinstalls from the **shared cache**. Because pixi hardlinks package files out of the cache (same filesystem), a fork costs a fraction of the environment's apparent size — measured at **74 MB of real disk for a 1.3 GB environment**. The fork shows up in JupyterLab as `<tool> (Pixi, mine)`, alongside the shared `<tool> (Pixi, shared)`.

The shared cache is group-writable via a default ACL for the workspace group, so `pixi add` works for users even though root wrote the cache first. A plain `1777` directory is not enough — pixi opens the repodata cache read-write, and root's files inside would be `644 root:root`.

## SRC Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PIXI_AI_TOOLS_VERSION` | `master` | Git branch or tag to deploy |
| `PIXI_AI_TOOLS_PRELOAD` | `all` | Comma-separated tools to pre-install, or `all`. Only pre-installed tools get a shared kernel. |

**Set `PIXI_AI_TOOLS_PRELOAD` to just the tools your course uses.** `all` pre-installs eight environments (~50 GB, a long deploy). Something like `cellpose,stardist,CAREamics` keeps the deploy short. This cost is paid once, at deploy time, before any student logs in — never on a student's first kernel click.

## Prerequisites

| Component | Required | Notes |
|-----------|----------|-------|
| SRC-OS (Ubuntu) | Yes | Debian-family only |
| SRC-External | Yes | Internet access for git clone + package downloads |
| Jupyter component | No | If present, kernels appear in JupyterLab automatically |
| GPU flavor | No | Recommended for the CUDA tools |

Disk: size the VM for the shared install (~50 GB for all eight environments) plus room for student forks and data.

## Usage

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
sudo ansible-playbook pixi-ai-tools.yml            # preloads everything
sudo env PIXI_AI_TOOLS_PRELOAD=cellpose,stardist ansible-playbook pixi-ai-tools.yml
```

## Available environments

| Environment | Description | CUDA |
|-------------|-------------|------|
| `biapy/` | BiaPy deep learning bioimage analysis | 12.8 |
| `CAREamics/` | Image denoising and restoration | 12.8 |
| `cellpose/` | Cell and nucleus segmentation | 12.8 |
| `micro_sam/` | Segment Anything for microscopy | 12.8 |
| `omero/` | OMERO image server client + Napari | — |
| `spotiflow/` | Spot detection in microscopy | 12.8 |
| `stardist/` | Star-convex object detection | 11.8 |
| `trackastra/` | Cell tracking for time-lapse data | 12.8 |

## Troubleshooting

**Kernels do not appear in the JupyterLab launcher.** Check that the allowlist override survived — an SRC Jupyter component update can rewrite the config:

```bash
grep -A1 "Spawner.args" /etc/jupyterhub/jupyterhub_config.py   # should NOT mention whitelist
sudo /etc/src/venv/jupyter-venv/bin/jupyter kernelspec list     # should list pixi-<tool>
```

**A kernel dies immediately.** Its environment was probably not pre-installed (`--frozen` fails when the env is missing). Run `ai-tools list` — anything showing `not built` has no usable shared kernel; add it to `PIXI_AI_TOOLS_PRELOAD` and re-run the playbook.

**A user's kernel shadows the shared one.** Kernelspecs in `~/.local/share/jupyter/kernels` win over system ones with the same name. The playbook removes per-user `pixi-<tool>` kernels that point at a home-directory clone; personal forks (`pixi-<tool>-mine`) use a distinct name and are left alone.

## Files

| File | Purpose |
|------|---------|
| `pixi-ai-tools.yml` | Main Ansible playbook |
| `requirements.yml` | Ansible collection dependencies (uusrc.general) |
| `files/setup-ai-tools.sh` | Per-user runonce script (completion, desktop launchers, cleanup) |
| `files/run-runonce.sh` | Runonce wrapper for the JupyterHub pre-spawn hook |
| `files/ai-tools` | User-facing helper: `list` / `fork` / `reset` |
