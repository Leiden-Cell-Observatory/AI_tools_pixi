# AI Tools with Pixi

This repository contains isolated AI/ML environments managed with [Pixi](https://pixi.sh), a modern package manager for scientific computing and data science.

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

## 📁 Repository Structure

Each folder contains its own isolated pixi environment with specific AI/ML tools:

### **CAREamics/** • [Documentation](https://careamics.github.io/)
Deep learning-based image restoration and denoising toolkit. Uses CUDA 12.8 with PyTorch.
- **Purpose**: Image denoising and restoration for microscopy images
- **Key packages**: careamics, torch, torchvision, bioio
- **Features**: Multiple environments (default, bioio, imagej)

### **cellpose/** • [Documentation](https://cellpose.readthedocs.io/en/latest/)
Generalist algorithm for cell and nucleus segmentation with GPU acceleration.
- **Purpose**: Cell segmentation using deep learning
- **Key packages**: cellpose 4 with GUI, PyTorch
- **CUDA**: 12.8

### **micro_sam/** • [Documentation](https://computational-cell-analytics.github.io/micro-sam/micro_sam.html)
Segment Anything Model (SAM) adapted for microscopy images.
- **Purpose**: Interactive and automatic segmentation for microscopy using napari
- **Key packages**: micro_sam, pytorch, napari-omero, trackastra
- **CUDA**: 12.8

### **biapy/** • [Documentation](https://biapy.readthedocs.io/en/latest/)
BiaPy - Library for training bioimage analysis AI models.
- **Purpose**: Training deep learning models for bioimage analysis workflows
- **Key packages**: biapy, mlflow (for experiment tracking), scikit-learn
- **Python**: 3.12

### **stardist/** • [GitHub](https://github.com/stardist/stardist)
Star-convex object detection in microscopy images, especially for segmentation of cell nuclei.
- **Purpose**: Object detection and instance segmentation
- **Key packages**: stardist, napari, tensorflow 2.10
- **CUDA**: 11.8 (older version for TensorFlow compatibility)

### **trackastra/** • [GitHub](https://github.com/weigertlab/trackastra)
Deep learning-based cell tracking for microscopy time-lapse data.
- **Purpose**: Cell tracking across time series
- **Key packages**: trackastra, PyTorch
- **CUDA**: 12.8

## 🔧 Using Pixi Environments

### Activating an Environment

Navigate to any folder and activate its environment:

```powershell
cd cellpose
#optionally run first
pixi install

pixi shell
```

This starts an interactive shell with all dependencies available. To exit, type `exit`.

### Running Applications

Each environment can run specific applications using pixi tasks:

```powershell
# In the cellpose folder
pixi run cellpose          # Launch Cellpose GUI

# In the stardist folder  
pixi run napari           # Launch Napari viewer

# Run Python in any environment
pixi run python           # Starts Python with all packages available
```

### Working with Jupyter Notebooks

Most environments include Jupyter support for interactive data analysis and experimentation:

```powershell
# Navigate to any folder with Jupyter support
cd CAREamics
# or: cd cellpose, micro_sam, biapy

# Launch Jupyter Lab with the correct Python environment
pixi run jupyter lab
```

**Environments with Jupyter**:
- ✅ CAREamics
- ✅ cellpose  
- ✅ micro_sam
- ✅ biapy
- ✅ stardist (via jupyter-client)
- ✅ trackastra

**Benefits**:
- 📓 Notebooks automatically use the correct Python environment
- 📦 All packages from `pixi.toml` are available in notebooks
- 🔬 Perfect for experimentation, visualization, and interactive analysis
- 🎯 No need to manually select kernels or worry about environment mismatches

### Running Custom Scripts

```powershell
# Navigate to the project folder
cd micro_sam

# Run Python scripts directly
pixi run python your_script.py

# Or activate the shell first
pixi shell
python your_script.py
```

## Using with Fiji plugins
These pixi environments can be used as well as replacement for setting up a conda environment for Fiji plugins requiring a conda environment to run Python tools such as Cellpose and Spotiflow.
For example they work with: https://github.com/BIOP/ijl-utilities-wrappers.

## 🧪 Testing CUDA Availability

Most environments include a `test-cuda` task to verify GPU setup:

```powershell
# In any folder with CUDA support
pixi run test-cuda
```

This command checks:
- ✅ CUDA availability
- 🔢 CUDA version
- 🖥️ GPU device count and name

### Example: Testing StarDist

```powershell
cd stardist
pixi run test-stardist
```

This runs `stardist_test.py` to verify the installation and GPU configuration.

## 📋 Understanding Pixi Tasks

Tasks are custom commands defined in `pixi.toml` files. They make common operations easy:

### Common Tasks

- **`test-cuda`**: Verifies PyTorch CUDA setup (available in: cellpose, micro_sam, trackastra, CAREamics, biapy)
- **`test-stardist`**: Tests StarDist installation and runs example code

### Viewing Available Tasks

```powershell
cd <project-folder>
pixi task list
```

### Running Tasks

```powershell
pixi run <task-name>
```

Tasks can be simple commands or complex scripts. Check each folder's `pixi.toml` to see available tasks.

## 💡 Understanding Pixi Environments

### How Pixi Environments Work

Each folder in this repository has its own **isolated environment**:

- 📁 **Folder-based**: Each project folder contains a `pixi.toml` configuration file
- 🐍 **Isolated Python**: Python and all dependencies are installed in a `.pixi` folder within each project
- 🔒 **No conflicts**: Different projects can use different Python versions and package versions
- 🚫 **No global installation**: Environments don't interfere with your system Python or other projects

**Example structure**:
```
cellpose/
  ├── pixi.toml          # Configuration file
  ├── pixi.lock          # Lock file for reproducibility
  └── .pixi/             # Environment folder (created automatically)
      └── envs/
          └── default/   # Python and packages installed here
```

### Creating Your Own Pixi Environment

Want to create a new AI tool environment? Here's how:

```powershell
# 1. Create a new folder and initialize pixi
mkdir my_project
cd my_project
pixi init

# 2. Add Python (specify your desired version)
pixi add python=3.12
# or: pixi add python=3.11, python=3.10, etc.

# 3. Add conda packages (from conda-forge)
pixi add numpy pandas matplotlib
pixi add pytorch torchvision

# 4. Add PyPI packages (from PyPI)
pixi add --pypi scikit-learn
pixi add --pypi transformers
pixi add --pypi napari-omero

# 5. Start using your environment
pixi shell              # Activate environment
pixi run python         # Run Python directly
pixi run jupyter lab    # Run Jupyter (if added)
```

### Conda vs PyPI Packages

**When to use `pixi add` (conda)**:
- ✅ System libraries and compiled packages (CUDA, OpenCV, etc.)
- ✅ Python itself and major scientific packages (numpy, scipy, pytorch)
- ✅ Generally faster and more reliable dependency resolution

**When to use `pixi add --pypi` (PyPI)**:
- ✅ Python-only packages not available in conda-forge
- ✅ Latest versions of packages that update frequently
- ✅ Packages specifically requiring pip installation

### How Pixi Resolves Dependencies

**Important**: Pixi resolves dependencies in a specific order:
1. **First**: Conda packages from conda-forge
2. **Then**: PyPI packages with pip

This means conda packages take priority. If you need a specific version from PyPI, ensure it's not being overridden by a conda package.

### Lock Files (`pixi.lock`)

Each environment has a `pixi.lock` file that ensures **reproducibility**:

- 📸 **Snapshot**: Contains exact versions of ALL dependencies (including transitive dependencies)
- 🔒 **Locked versions**: Anyone running `pixi install` gets the identical environment
- 🌐 **Cross-platform**: Includes platform-specific dependency resolution
- ♻️ **Update control**: Dependencies only change when you run `pixi update` or modify `pixi.toml`

**Think of it as**: A detailed receipt of your exact environment that guarantees the same setup on any machine.

### Platform Support

```toml
platforms = ["win-64", "linux-64"]
```

This declaration:
- ✅ Generates lock file entries for **both Windows and Linux** (64-bit)
- 🖥️ Allows the same `pixi.toml` to work on both platforms
- 🔄 Enables collaboration across different operating systems
- 📦 Pixi automatically uses the correct platform when installing

Common platforms:
- `win-64`: Windows 64-bit
- `linux-64`: Linux 64-bit  
- `osx-64`: macOS Intel
- `osx-arm64`: macOS Apple Silicon

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
# Clean and reinstall
pixi clean
pixi install
```

### CUDA Not Detected
- Ensure NVIDIA drivers are up to date
- Check system CUDA version matches `pixi.toml` requirements
- Run `pixi run test-cuda` to diagnose

### Package Conflicts
- Check `pixi.toml` for version constraints
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
