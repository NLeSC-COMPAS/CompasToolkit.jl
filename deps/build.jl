using Scratch

const MODULE_UUID = Base.UUID("7e3df991-ca6f-4721-8d7b-832e42ca037e")

function get_nvcc_path_and_validate()
    # 1. Find nvcc in PATH
    nvcc_path = Sys.which("nvcc")
    if nvcc_path === nothing
        error("nvcc not found in PATH. Please make sure Pixi is in your PATH.")
    end

    # 2. Check Version
    try
        out = readchomp(`$nvcc_path --version`)
        m = match(r"release (\d+)\.(\d+)", out)
        if m === nothing
            error("Could not parse nvcc version.")
        end

        major_ver = parse(Int, m.captures[1])
        if major_ver < 12
            error("CompasToolkit requires CUDA 12+. Found v$(m.match) at $nvcc_path")
        else
            @info "Found compatible CUDA compiler: v$(m.match) at $nvcc_path"
        end
    catch e
        error("Failed to verify CUDA version: $e")
    end
    return nvcc_path
end

function build_library()
    PKG_ROOT = dirname(@__DIR__)
    BUILD_DIR = get_scratch!(MODULE_UUID, "build")
    PREFIX_DIR = get_scratch!(MODULE_UUID, "prefix")

    # Detect compilers
    # Prefer locally installed CUDA 12.2 (pixi has 12.4, system has 11.8)
    nvcc_candidates = [
        joinpath(ENV["HOME"], ".local", "opt", "cuda-12.2", "bin", "nvcc"),
        joinpath(ENV["HOME"], "cuda-12.2", "bin", "nvcc"),  # Fallback to old location
        joinpath(ENV["HOME"], ".pixi", "envs", "cuda-nvcc", "bin", "nvcc"),
        joinpath(ENV["HOME"], ".pixi", "envs", "cuda-toolkit", "bin", "nvcc"),
        "/usr/local/cuda/bin/nvcc",
        "/usr/bin/nvcc"
    ]

    nvcc_path = nothing
    for candidate in nvcc_candidates
        @info "Checking nvcc candidate: $candidate (exists: $(isfile(candidate)))"
        if isfile(candidate)
            nvcc_path = candidate
            @info "Found nvcc at: $nvcc_path"
            break
        end
    end

    if nvcc_path === nothing
        # Fall back to pixi or PATH
        pixi_nvcc = expanduser("~/.pixi/envs/cuda-nvcc/bin/nvcc")
        if isfile(pixi_nvcc)
            nvcc_path = pixi_nvcc
            @info "Using pixi nvcc at: $nvcc_path"
        else
            nvcc_path = Sys.which("nvcc")
            if nvcc_path === nothing
                error("nvcc not found! Please install CUDA toolkit.")
            end
        end
    end

    # Validate CUDA version
    try
        out = readchomp(`$nvcc_path --version`)
        m = match(r"release (\d+)\.(\d+)", out)
        if m === nothing
            @warn "Could not parse CUDA version from: $out"
        else
            major_ver = parse(Int, m.captures[1])
            minor_ver = parse(Int, m.captures[2])
            cuda_ver = "$major_ver.$minor_ver"
            @info "Found CUDA compiler version: $cuda_ver at $nvcc_path"

            # CUDA 11.8+ or 12.x should work with driver 535 (CUDA 12.2)
            if major_ver < 11 || (major_ver == 11 && minor_ver < 8)
                @warn "CUDA $cuda_ver is older than recommended (11.8+)"
            end
        end
    catch e
        @warn "Could not verify CUDA version: $e"
    end

    # Find g++-11 for CUDA 12.2 compatibility (CUDA 12.2 requires GCC <= 11)
    gxx_path = Sys.which("g++-11")
    if gxx_path === nothing
        # Fall back to g++ if g++-11 not found
        gxx_path = Sys.which("g++")
        if gxx_path === nothing
            error("g++ not found! Please install a C++ compiler.")
        end
        @warn "Using $(gxx_path), but CUDA 12.2 requires GCC 11 or older"
    else
        @info "Using GCC 11: $gxx_path"
    end

    # Clean old cache
    rm(joinpath(BUILD_DIR, "CMakeCache.txt"), force=true)
    rm(joinpath(BUILD_DIR, "CMakeFiles"), recursive=true, force=true)

    # Configure
    # Use CUDA toolkit matching the nvcc compiler
    # If using pixi nvcc, use pixi libraries; otherwise use system
    cuda_toolkit_root = ""

    if contains(nvcc_path, ".pixi")
        # Using pixi nvcc - use pixi toolkit
        cuda_toolkit_candidates = [
            expanduser("~/.pixi/envs/cuda-libraries-dev"),
            expanduser("~/.pixi/envs/cuda-toolkit"),
            expanduser("~/.pixi/envs/cuda-libraries"),
            dirname(dirname(nvcc_path))  # Go up from bin/nvcc to root
        ]
    elseif contains(nvcc_path, "cuda-12.2")
        # Using local CUDA 12.2 installation
        cuda_toolkit_candidates = [
            expanduser("~/.local/opt/cuda-12.2"),
            expanduser("~/cuda-12.2"),  # Fallback to old location
            dirname(dirname(nvcc_path))  # Go up from bin/nvcc to root
        ]
    else
        # Using system nvcc - use system toolkit
        cuda_toolkit_candidates = [
            "/usr",  # System CUDA in /usr/include, /usr/lib
            "/usr/local/cuda",
            dirname(dirname(nvcc_path))  # Go up from bin/nvcc to root
        ]
    end

    for candidate in cuda_toolkit_candidates
        cuda_header = joinpath(candidate, "include", "cuda_runtime.h")
        if isfile(cuda_header)
            cuda_toolkit_root = candidate
            @info "Using CUDA toolkit at: $cuda_toolkit_root"
            break
        end
    end

    if isempty(cuda_toolkit_root)
        error("CUDA toolkit headers not found!")
    end

    configure_cmd = `cmake -S $(PKG_ROOT) -B $(BUILD_DIR)
        -DCMAKE_INSTALL_PREFIX=$(PREFIX_DIR)
        -DCMAKE_CUDA_COMPILER=$(nvcc_path)
        -DCMAKE_CUDA_HOST_COMPILER=$(gxx_path)
        -DCUDAToolkit_ROOT=$(cuda_toolkit_root)
        -DCUDAToolkit_INCLUDE_DIR=$(cuda_toolkit_root)/include
        -DCMAKE_BUILD_TYPE=Release`

    @info "Configuring CompasToolkit..."
    run(configure_cmd)

    # Build
    build_cmd = `cmake --build $(BUILD_DIR) --config Release -j $(Sys.CPU_THREADS)`
    @info "Compiling..."
    run(build_cmd)

    # Install
    install_cmd = `cmake --install $(BUILD_DIR)`
    @info "Installing..."
    run(install_cmd)

    @info "Build complete. Library installed in: $PREFIX_DIR"
end

build_library()
