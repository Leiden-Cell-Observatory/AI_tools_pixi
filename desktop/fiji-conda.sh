#!/usr/bin/env bash
# Let Fiji plugins that expect a conda environment use the pixi environments.
#
#   desktop/fiji-conda.sh            register / update
#   desktop/fiji-conda.sh --remove   undo
#
# 1. Every installed tool environment is linked into conda's envs directory as
#    `pixi-<tool>` (e.g. pixi-cellpose). `conda env list` then shows it by
#    name, which is what TrackMate's conda-based detectors (Edit > Options >
#    Configure TrackMate Conda path...) and similar plugins offer to pick from.
#    The pixi environments are all called `default`, so registering their paths
#    in ~/.conda/environments.txt instead would give indistinguishable names.
# 2. The BIOP cellpose wrapper (Plugins > BIOP > Cellpose) is pointed at the
#    cellpose environment. On Linux its "conda" type runs
#    <env>/bin/python -m cellpose directly. Values you already set in the
#    wrapper's dialog are kept.
#
# Needs a conda installation (conda, mamba or miniforge) for part 1; set
# CONDA_ROOT to choose one, otherwise `conda info --base` decides.
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
remove=false
[ "${1:-}" = "--remove" ] && remove=true

# ---- 1. conda env names -----------------------------------------------------
conda_root=${CONDA_ROOT:-}
if [ -z "$conda_root" ]; then
    for c in "${CONDA_EXE:-}" "$(command -v conda || true)" "$HOME/miniforge3/bin/conda" \
             "$HOME/miniconda3/bin/conda" "$HOME/anaconda3/bin/conda"; do
        if [ -n "$c" ] && [ -x "$c" ]; then conda_root=$("$c" info --base); break; fi
    done
fi

if [ -z "$conda_root" ]; then
    echo "no conda found: skipping conda registration (set CONDA_ROOT)"
else
    envs_dir="$conda_root/envs"
    mkdir -p "$envs_dir"
    for manifest in "$REPO"/*/pixi.toml; do
        tool_dir=$(dirname "$manifest")
        link="$envs_dir/pixi-$(basename "$tool_dir")"
        target="$tool_dir/.pixi/envs/default"
        # Only ever touch links that point into this repository.
        if [ -L "$link" ] && [[ "$(readlink "$link")" != "$REPO/"* ]]; then
            echo "skip $link: not ours"; continue
        fi
        if $remove || [ ! -d "$target" ]; then
            [ -L "$link" ] && rm -v "$link"
            continue
        fi
        [ -e "$link" ] && [ ! -L "$link" ] && { echo "skip $link: exists"; continue; }
        ln -sfn "$target" "$link"
        echo "conda env $(basename "$link") -> $target"
    done
fi

# ---- 2. BIOP cellpose wrapper -----------------------------------------------
cellpose_env="$REPO/cellpose/.pixi/envs/default"
prefs_root="$HOME/.java/.userPrefs/ch/epfl/biop/wrappers/cellpose/ij2commands"
for cmd in Cellpose CellposeSAM; do
    prefs="$prefs_root/$cmd/prefs.xml"
    if $remove; then
        grep -qs "$cellpose_env" "$prefs" && rm -v "$prefs"
        continue
    fi
    [ -x "$cellpose_env/bin/python" ] || { echo "cellpose not installed: skipping BIOP prefs"; break; }
    [ -e "$prefs" ] && { echo "BIOP $cmd already configured, left alone"; continue; }
    mkdir -p "$(dirname "$prefs")"
    cat > "$prefs" <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
<map MAP_XML_VERSION="1.0">
<entry key="env_path" value="$cellpose_env"/>
<entry key="env_type" value="conda"/>
</map>
EOF
    echo "BIOP $cmd -> $cellpose_env"
done
