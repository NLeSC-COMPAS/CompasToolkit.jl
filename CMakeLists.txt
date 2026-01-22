cmake_minimum_required(VERSION 3.10)
project("compas-toolkit-julia" LANGUAGES CXX VERSION 0.2)

# Set CUDA architecture to 80
if(NOT CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 80)
endif()

# Include compas toolkit
add_subdirectory(compas-toolkit)

# Create bindings library
file(GLOB sources "${CMAKE_CURRENT_SOURCE_DIR}/bindings/*.cpp")
add_library(compas-julia SHARED ${sources})
target_compile_features(compas-julia PRIVATE cxx_std_17)

if(COMPAS_USE_CUDA)
    set_target_properties(compas-julia PROPERTIES CUDA_ARCHITECTURES ${CMAKE_CUDA_ARCHITECTURES})
elseif(COMPAS_USE_HIP)
    set_source_files_properties(${sources} PROPERTIES LANGUAGE HIP)
endif()

# Local installation path
set(CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}")
install(TARGETS compas-julia LIBRARY DESTINATION lib)

# Link with toolkit
target_link_libraries(compas-julia compas-toolkit)

# Configure local files
configure_file(
    ${PROJECT_SOURCE_DIR}/src/Constants.jl.input
    ${PROJECT_SOURCE_DIR}/src/Constants.jl)
configure_file(
    ${PROJECT_SOURCE_DIR}/bindings/constants.h.input
    ${PROJECT_SOURCE_DIR}/bindings/constants.h)
