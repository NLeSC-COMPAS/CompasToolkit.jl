# Guide: Submitting KMM Patch Upstream

## Background
We've patched KMM to handle unsupported GPU attributes gracefully. This patch is necessary when KMM is compiled with CUDA 12.4+ headers but runs with CUDA 12.2 drivers.

## Problem
When compiled with newer CUDA headers, KMM attempts to query GPU attributes that don't exist in older drivers, causing `cudaErrorInvalidValue` and crashing GPU initialization.

## Solution
Modified `compas-toolkit/thirdparty/kmm/src/core/system_info.cpp` to catch `cudaErrorInvalidValue` and set unsupported attributes to 0 instead of failing.

## Steps to Submit PR

### 1. Fork the KMM Repository
Visit: https://github.com/NLeSC-COMPAS/kmm
Click "Fork" button → Create fork to your account

### 2. Clone Your Fork
```bash
git clone https://github.com/YOUR_USERNAME/kmm.git
cd kmm
git remote add upstream https://github.com/NLeSC-COMPAS/kmm.git
```

### 3. Create Feature Branch
```bash
git checkout -b fix/cuda-attribute-compatibility
```

### 4. Apply the Patch
```bash
# From your CompasToolkit.jl directory:
cd /path/to/CompasToolkit.jl
cp kmm-cuda-compatibility.patch /path/to/kmm/

# In your kmm directory:
cd /path/to/kmm
git apply kmm-cuda-compatibility.patch
```

### 5. Commit the Changes
```bash
git add src/core/system_info.cpp
git commit -m "Handle unsupported GPU attributes gracefully

When querying GPU device attributes, some attributes may not be supported
by older CUDA drivers. Instead of failing with cudaErrorInvalidValue,
gracefully handle this by setting unsupported attributes to 0.

This allows KMM to work with CUDA 12.2 drivers when compiled with
CUDA 12.4+ headers that define newer attributes.

The issue occurs when:
1. Code is compiled with CUDA 12.4+ headers (which define newer attributes)
2. Runtime uses CUDA 12.2 driver (which doesn't support those attributes)
3. gpuDeviceGetAttribute() returns cudaErrorInvalidValue for unknown attributes

This patch catches that specific error and sets the attribute value to 0,
allowing initialization to continue successfully.
"
```

### 6. Push to Your Fork
```bash
git push origin fix/cuda-attribute-compatibility
```

### 7. Create Pull Request
1. Visit: https://github.com/YOUR_USERNAME/kmm
2. Click "Compare & pull request" button
3. Set base repository: `NLeSC-COMPAS/kmm` base: `main`
4. Set head repository: `YOUR_USERNAME/kmm` compare: `fix/cuda-attribute-compatibility`
5. Fill in the PR description (see template below)
6. Click "Create pull request"

## PR Description Template

```markdown
## Fix: Handle unsupported GPU attributes gracefully

### Problem
When KMM is compiled with CUDA 12.4+ headers but runs with CUDA 12.2 drivers, GPU initialization fails with `cudaErrorInvalidValue` during device attribute querying.

### Root Cause
Newer CUDA headers define GPU attributes that older drivers don't support. The current code crashes when querying these unsupported attributes:
```cpp
KMM_GPU_CHECK(gpuDeviceGetAttribute(&m_attributes[i], attr, m_device_id));
```

### Solution
Modified `src/core/system_info.cpp` to catch `cudaErrorInvalidValue` and set unsupported attributes to 0:
```cpp
auto result = gpuDeviceGetAttribute(&m_attributes[i], attr, m_device_id);
if (result == cudaErrorInvalidValue) {
    m_attributes[i] = 0;  // Set unsupported attributes to 0
    continue;
}
KMM_GPU_CHECK(result);
```

### Testing
Tested on:
- **Hardware**: NVIDIA RTX A5000 GPU
- **Driver**: 535.261.03 (supports CUDA 12.2)
- **Compiled with**: CUDA 12.4 headers
- **Result**: GPU initialization succeeds, all functionality works

### Impact
- No breaking changes
- Backward compatible
- Allows KMM to work across CUDA version mismatches
- Sets unsupported attributes to 0 (safe default)

### Related Issues
This fixes GPU initialization failures when:
1. Using newer CUDA SDK for compilation
2. Running on systems with older CUDA drivers
3. Driver version < SDK version used for compilation
```

## After PR is Merged

Once the upstream PR is merged, you can update your CompasToolkit:

```bash
cd /localscratch/oheide/projects/escience_center/compas/CompasToolkit.jl

# Pull latest from upstream compas-toolkit
git subtree pull --prefix compas-toolkit https://github.com/NLeSC-COMPAS/compas-toolkit.git main --squash

# The patch will be part of the upstream code now!
```

## If PR Takes Time

Until the PR is merged, colleagues can use your oscar/subtree branch:

```julia
using Pkg
Pkg.add(url="https://github.com/NLeSC-COMPAS/CompasToolkit.jl", rev="oscar/subtree")
```

This branch includes:
- ✅ All dependencies vendored (git subtree)
- ✅ KMM patch applied
- ✅ Works with Pkg.add()
- ✅ No submodule issues

## Contact
If you have questions about the patch, feel free to reach out!
