# AI Tools with Pixi

This repository contains isolated AI/ML environments managed with [Pixi](https://pixi.sh), a modern package manager for scientific computing and data science. All tools are defined in a single `pixi.toml` at the project root using pixi's [multi-environment](https://pixi.sh/latest/workspace/multi_environment/) feature — install only the environments you need.

## 📦 What is Pixi?

**Pixi** is a fast, cross-platform package manager that combines the best of conda and pip:

- **vs Conda**: Pixi is faster, uses a modern lock file format for reproducibility, and provides a better developer experience with tasks and workspaces
- **vs Pip**: Pixi handles both Python and non-Python dependencies (like CUDA, system libraries), manages Python versions automatically, and creates isolated environments per project
- **Best of both**: Install packages from conda-forge AND PyPI in the same environment, with automatic dependency resolution

## 🚀 Installing Pixi

### Windows (PowerShell)
```powershell
iwr -useb https://pixi.sh/install.ps1 | iex
```

### Linux & macOS
```bash
curl -fsSL https://pixi.sh/install.sh | sh
```

Or with wget:
```bash
wget -qO- https://pixi.sh/install.sh | sh
```

After installation, restart your terminal to use pixi.

For more installation options, visit: https://pixi.sh/dev/installation/

## 📁 Available Environments

All environments are defined in the root `pixi.toml`. Each environment is fully isolated with its own Python version, CUDA requirements, and dependencies.

| Environment | Description | Python | CUDA | Key Packages |
|---|---|---|---|---|
| `biapy` | Training bioimage analysis AI models ([docs](https://biapy.readthedocs.io/en/latest/)) | 3.12 | 12.8 | biapy, mlflow, scikit-learn, PyTorch |
| `cellpose` | Cell and nucleus segmentation ([docs](https://cellpose.readthedocs.io/en/latest/)) | 3.11 | 12.8 | cellpose (with GUI), PyTorch |
| `stardist` | Star-convex object detection ([GitHub](https://github.com/stardist/stardist)) | 3.10 | 11.8 | stardist, napari, TensorFlow 2.10 |
| `trackastra` | Deep learning cell tracking ([GitHub](https://github.com/weigertlab/trackastra)) | 3.11 | 12.8 | trackastra, PyTorch |
| `spotiflow` | Spot detection in microscopy | 3.12 | 12.8 | spotiflow, PyTorch |
| `omero` | OMERO image data management | 3.10 | — | omero-py, napari, napari-omero |
| `micro_sam` | Segment Anything for microscopy ([docs](https://computational-cell-analytics.github.io/micro-sam/micro_sam.html)) | 3.11 | 12.8 | micro_sam, PyTorch, trackastra, napari-omero |
| `careamics` | Image restoration and denoising ([docs](https://careamics.github.io/)) | 3.11 | 12.8 | careamics, torch (PyPI), napari, bioio |
| `careamics-all` | CAREamics with all optional features | 3.11 | 12.8 | careamics + bioio + pyimagej |

## 🔧 Using Pixi Environments

### Quick Start

From the repository root, install and activate any environment:

```powershell
# Install a specific environment (only downloads what you need)
pixi install -e cellpose

# Activate a shell with that environment
pixi shell -e cellpose

# Or run a command directly
pixi run -e cellpose python your_script.py
```

> **Important**: Always use `pixi install -e <name>` to install a specific environment.
> Running `pixi install` without `-e` will attempt to install ALL environments.

### Running Applications

```powershell
# Launch Cellpose GUI
pixi run -e cellpose python -m cellpose

# Run Python in any environment
pixi run -e micro_sam python

# Run a script
pixi run -e biapy python train.py
```

### Working with Jupyter Notebooks

Most environments include Jupyter support:

```powershell
# Launch Jupyter Lab with the careamics environment
pixi run -e careamics jupyter lab

# Or with cellpose, micro_sam, biapy, trackastra, spotiflow...
pixi run -e cellpose jupyter lab
```

**Environments with Jupyter**: biapy, cellpose, micro_sam, trackastra, spotiflow, careamics, stardist (via jupyter-client)

## Using with Fiji plugins
These pixi environments can be used as well as replacement for setting up a conda environment for Fiji plugins requiring a conda environment to run Python tools such as Cellpose and Spotiflow.
For example they work with: https://github.com/BIOP/ijl-utilities-wrappers.

## 🧪 Testing CUDA Availability

Most environments include a `test-cuda` task to verify GPU setup:

```powershell
pixi run -e cellpose test-cuda
pixi run -e biapy test-cuda
pixi run -e micro_sam test-cuda
```

This checks CUDA availability, version, device count, and GPU name.

### Testing StarDist

```powershell
pixi run -e stardist test-stardist
```

This runs `stardist_test.py` to verify the installation and GPU configuration.

## 📋 Tasks

Tasks are defined per-environment in the `pixi.toml`:

| Task | Environments | Description |
|---|---|---|
| `test-cuda` | biapy, cellpose, trackastra, spotiflow, micro_sam | Verify PyTorch CUDA setup |
| `test-stardist` | stardist | Test StarDist installation |

Run any task with:
```powershell
pixi run -e <environment> <task-name>
```

## 💡 How It Works

### Multi-Environment Architecture

All tools are defined in a single `pixi.toml` using pixi's [feature/environment](https://pixi.sh/latest/workspace/multi_environment/) system:

- Each tool is a **feature** containing all its dependencies (Python version, CUDA, packages)
- Each tool maps to an **environment** with `no-default-feature = true` (complete isolation)
- Environments don't share dependencies — different Python versions and CUDA versions coexist

```
AI_tools_pixi/
  ├── pixi.toml           # All environments defined here
  ├── pixi.lock           # Lock file for all environments
  └── .pixi/
      └── envs/
          ├── biapy/      # Python 3.12 + CUDA 12.8
          ├── cellpose/   # Python 3.11 + CUDA 12.8
          ├── stardist/   # Python 3.10 + CUDA 11.8
          └── ...         # Only installed envs appear here
```

### Adding a New Tool

To add a new AI tool, add a feature and environment to `pixi.toml`:

```toml
# Define the feature with all dependencies
[feature.my_tool.dependencies]
python = "3.12.*"
pytorch = ">=2.7.1,<3"
jupyter = ">=1.1.1,<2"

[feature.my_tool.system-requirements]
cuda = "12.8"

[feature.my_tool.pypi-dependencies]
my-package = ">=1.0, <2"

[feature.my_tool.tasks]
test-cuda = "python -c \"import torch; print(torch.cuda.is_available())\""

# Register the environment
[environments]
# ... existing environments ...
my_tool = { features = ["my_tool"], no-default-feature = true }
```

Then install with `pixi install -e my_tool`.

### Conda vs PyPI Packages

**When to use conda** (`[feature.<name>.dependencies]`):
- System libraries and compiled packages (CUDA, OpenCV, etc.)
- Python itself and major scientific packages (numpy, scipy, pytorch)
- Generally faster and more reliable dependency resolution

**When to use PyPI** (`[feature.<name>.pypi-dependencies]`):
- Python-only packages not available in conda-forge
- Latest versions of packages that update frequently
- Packages specifically requiring pip installation

### Lock Files (`pixi.lock`)

The repository has a single `pixi.lock` file that covers all environments:

- Contains exact versions of ALL dependencies (including transitive) for every environment
- Anyone running `pixi install -e <env>` gets an identical environment
- Includes platform-specific resolution for both Windows and Linux
- Dependencies only change when you run `pixi update` or modify `pixi.toml`

## ⚠️ PyTorch Installation Challenges (Especially on Windows)

PyTorch with CUDA can be tricky. Here are two approaches used in this repository:

### Approach 1: Conda PyTorch (Recommended)

Install PyTorch via conda and specify CUDA requirements:

```toml
[dependencies]
pytorch = ">=2.7.1,<3"

[system-requirements]
cuda = "12.8"
```

**Used in**: cellpose, micro_sam, trackastra, biapy

**Pros**: 
- ✅ Cleaner dependency resolution
- ✅ CUDA compatibility handled automatically
- ✅ Better integration with conda packages

### Approach 2: PyPI PyTorch with Custom Index

For some packages that require pip-installed PyTorch:

```toml
[pypi-dependencies]
torch = "*"
torchvision = "*"

[pypi-options]
extra-index-urls = ["https://download.pytorch.org/whl/cu118"]
index-strategy = "unsafe-best-match"
```

**Used in**: CAREamics (for compatibility with specific dependencies)

**Pros**:
- ✅ Access to latest PyPI releases
- ✅ Better compatibility with PyPI-only packages
- ✅ Custom CUDA versions via wheel URLs

**When to use PyPI approach**:
- Package explicitly requires pip-installed PyTorch
- Need a specific PyTorch version not available in conda
- Compatibility issues with conda PyTorch build

### Windows-Specific Notes

🪟 **Windows users**: PyTorch CUDA support requires:
1. Compatible NVIDIA GPU
2. Updated NVIDIA drivers
3. Matching CUDA toolkit version (handled by pixi via `system-requirements`)
4. Correct PyTorch wheel for your CUDA version

**Tip**: Always run `pixi run test-cuda` after installation to verify GPU detection.

## 🆘 Troubleshooting

### Environment Issues
```powershell
# Clean and reinstall a specific environment
pixi clean
pixi install -e cellpose
```

### CUDA Not Detected
- Ensure NVIDIA drivers are up to date
- Check system CUDA version matches the environment's requirements
- Run `pixi run -e <env> test-cuda` to diagnose

### Package Conflicts
- Check the relevant feature section in `pixi.toml` for version constraints
- Update pixi: `pixi self-update`

## 🤝 Contributing

Contributions, suggestions, and improvements are welcome!

- 💡 **Have a suggestion?** Open an [issue](https://github.com/maartenpaul/AI_tools_pixi/issues) to propose new tools or improvements
- 🐛 **Found a bug?** Report it via [issues](https://github.com/maartenpaul/AI_tools_pixi/issues)
- ✨ **Want to add a new AI tool?** Contributions are appreciated! Feel free to submit a pull request

## 📖 Additional Resources

- [Pixi Documentation](https://pixi.sh)
- [Pixi GitHub](https://github.com/prefix-dev/pixi)
- [Community Examples](https://github.com/prefix-dev/pixi/tree/main/examples)

## 👤 Author

Maarten Paul (m.w.paul@lumc.nl)
