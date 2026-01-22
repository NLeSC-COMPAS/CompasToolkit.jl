using Scratch

const MODULE_UUID = Base.UUID("7e3df991-ca6f-4721-8d7b-832e42ca037e")

function build_library()
    PKG_ROOT = dirname(@__DIR__)
    BUILD_DIR = get_scratch!(MODULE_UUID, "build")

    cmd = `cmake -S $(PKG_ROOT) -B$(BUILD_DIR)`
    run(cmd)

    cmd = `cmake --install $(BUILD_DIR)`
    run(cmd)
end

build_library()
