# CompasToolkit.jl Installation Guide

## The Problem with Git Submodules

Julia's `Pkg.add()` from GitHub **does not work** with git submodules due to a fundamental limitation in Julia's package manager ([issue #708](https://github.com/JuliaLang/Pkg.jl/issues/708)). When you try `Pkg.add(url="...")` with a repository containing submodules, you'll get errors like:

```
GitError(Code:ENOTFOUND, Class:Odb, odb: cannot read object: null OID cannot exist)
```

or

```
GitError(Code:ERROR, Class:Submodule, cannot get submodules without a working tree)
```

**This is not fixable** - it's a limitation of how Julia's Pkg system clones repositories.

## ✅ Working Installation Methods

### Option 1: Local Development (Recommended for You)

Use your local working directory directly:

```julia
using Pkg
Pkg.develop(path="/localscratch/oheide/projects/escience_center/compas/CompasToolkit.jl")
```

This uses your local files without any git operations.

### Option 2: Tarball Distribution (Recommended for Colleagues)

Share the pre-built tarball `/localscratch/oheide/projects/escience_center/compas/CompasToolkit.jl-vendored.tar.gz` (9.5 MB)

**For colleagues:**
```bash
# Extract the tarball
tar xzf CompasToolkit.jl-vendored.tar.gz
cd CompasToolkit.jl

# Install in Julia
julia -e 'using Pkg; Pkg.develop(path=".")'
```

The tarball includes:
- ✅ All vendored dependencies (no submodules)
- ✅ KMM patch applied
- ✅ No `.git` directories (clean)
- ✅ Ready to use with CUDA 12.2

### Option 3: Personal Fork on GitHub (Alternative)

If you have your own GitHub account, you can push there:

```bash
# Add your personal remote
git remote add personal https://github.com/YOUR_USERNAME/CompasToolkit.jl.git

# Push the vendored branch
git push personal oscar/subtree-v2

# Then colleagues can:
# julia -e 'using Pkg; Pkg.add(url="https://github.com/YOUR_USERNAME/CompasToolkit.jl", rev="oscar/subtree-v2")'
```

## Prerequisites

### CUDA 12.2.2 Setup

Before using CompasToolkit, install CUDA 12.2:

```bash
# Run the setup script (creates ~/.local/opt/cuda-12.2)
bash setup_cuda_12.2.sh

# Add to your shell RC file (~/.bashrc or ~/.zshrc):
export PATH="$HOME/.local/opt/cuda-12.2/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/opt/cuda-12.2/lib64:$LD_LIBRARY_PATH"

# Reload your shell
source ~/.bashrc  # or ~/.zshrc
```

### Verify CUDA Installation

```bash
nvcc --version  # Should show: Cuda compilation tools, release 12.2
nvidia-smi      # Should show your GPU
```

## Usage

Once installed, test it:

```julia
using CompasToolkit

# Initialize GPU context
CompasToolkit.init_context()
# Should output: [info] detected 1 GPU device(s): NVIDIA RTX A5000 (25 GB)

# Run examples
include("examples/helloworld.jl")
```

## Why This Solution Works

The vendored approach (tarball or `Pkg.develop`) works because:

1. **No git submodules** - All dependencies are regular files
2. **No remote git operations** - Everything is local
3. **KMM patch included** - GPU compatibility fix applied
4. **CUDA 12.2 compatible** - Works with your driver version

## For Upstreaming

The KMM patch in `kmm-cuda-compatibility.patch` should be submitted to:
- https://github.com/NLeSC-COMPAS/kmm

See `UPSTREAM_PR_GUIDE.md` for instructions.

## Troubleshooting

### "Cannot find libcublas.so.12"
Make sure CUDA 12.2 is in your `LD_LIBRARY_PATH`:
```bash
export LD_LIBRARY_PATH="$HOME/.local/opt/cuda-12.2/lib64:$LD_LIBRARY_PATH"
```

### "GPU initialization failed"
1. Check driver supports CUDA 12.2: `nvidia-smi`
2. Verify KMM patch is applied: `grep -A5 "cudaErrorInvalidValue" compas-toolkit/thirdparty/kmm/src/core/system_info.cpp`

### Build fails
Make sure GCC 11 is available:
```bash
gcc --version  # Should be 11.x
```

## Summary

✅ **Use `Pkg.develop(path="...")` locally**  
✅ **Share `CompasToolkit.jl-vendored.tar.gz` with colleagues**  
❌ **Don't use `Pkg.add(url="...")` from GitHub** (won't work with submodules)

