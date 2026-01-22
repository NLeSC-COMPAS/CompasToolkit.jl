# Running CompasToolkit with CUDA

## Issue Summary
The library requires CUDA runtime libraries to be accessible via `LD_LIBRARY_PATH`. 

## Solution

### Option 1: Use the wrapper script (Recommended)
Run Julia using the provided wrapper script:
```bash
./start_julia.sh
```

### Option 2: Set LD_LIBRARY_PATH manually
Before starting Julia, set the environment variable:
```bash
export LD_LIBRARY_PATH="/home/oheide/.pixi/envs/cuda-toolkit/lib:${LD_LIBRARY_PATH}"
julia --project=.
```

### Option 3: Add to your shell profile
Add this line to your `~/.bashrc` or `~/.zshrc`:
```bash
export LD_LIBRARY_PATH="/home/oheide/.pixi/envs/cuda-toolkit/lib:${LD_LIBRARY_PATH}"
```

## Verifying GPU Access
Once Julia is running with the proper library path, you can test:
```julia
using CompasToolkit
CompasToolkit.init_context()  # Should successfully initialize
```

## Troubleshooting

### GPU Driver Error (CUDA_ERROR_INVALID_VALUE)
If you see this error, it may be due to:
1. CUDA version mismatch between runtime (12.4) and driver (12.2)
2. GPU is busy with other processes
3. Permissions issue accessing the GPU

Try:
- Checking `nvidia-smi` to see GPU status
- Ensuring no conflicting CUDA installations
- Recompiling with matching CUDA version

### Library Not Found
If you see `libcublas.so.12: cannot open shared object file`:
- Verify CUDA is installed: `which nvcc`
- Check the library exists: `ls /home/oheide/.pixi/envs/cuda-toolkit/lib/libcublas.so.12`
- Ensure LD_LIBRARY_PATH is set before Julia starts
