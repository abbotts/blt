# Copyright (c) 2017-2019, Lawrence Livermore National Security, LLC and
# other BLT Project Developers. See the top-level COPYRIGHT file for details
#
# SPDX-License-Identifier: (BSD-3-Clause)

# Author: Noel Chalmers @ Advanced Micro Devices, Inc.
# Date: March 11, 2019

################################
# HIP
################################
set (CMAKE_MODULE_PATH "${BLT_ROOT_DIR}/cmake/thirdparty;${CMAKE_MODULE_PATH}")
find_package(HIP REQUIRED)

message(STATUS "HIP version:      ${HIP_VERSION_STRING}")
message(STATUS "HIP platform:     ${HIP_PLATFORM}")
#message(STATUS "HIP Include Path: ${HIP_INCLUDE_DIRS}")
#message(STATUS "HIP Libraries:    ${HIP_LIBRARIES}")

set(HIP_RUNTIME_INCLUDE_DIRS "${HIP_ROOT_DIR}/include")
if(${HIP_PLATFORM} STREQUAL "hcc")
	set(HIP_RUNTIME_DEFINES "-D__HIP_PLATFORM_HCC__")
    set(HIP_RUNTIME_LIBRARIES "${HIP_ROOT_DIR}/lib/libhip_hcc.so")
elseif(${HIP_PLATFORM} STREQUAL "clang")
    set(HIP_RUNTIME_DEFINES "-D__HIP_PLATFORM_HCC__;-D__HIP_ROCclr__")
    set(HIP_RUNTIME_LIBRARIES "${HIP_ROOT_DIR}/lib/libamdhip64.so")
elseif(${HIP_PLATFORM} STREQUAL "nvcc")
    set(HIP_RUNTIME_DEFINES "-D__HIP_PLATFORM_NVCC__")
    find_package(cudatoolkit)
    set(HIP_RUNTIME_LIBRARIES "${CUDAToolkit_LIBRARY_DIR}/libcudart.so")
    set(HIP_RUNTIME_INCLUDE_DIRS "${HIP_RUNTIME_INCLUDE_DIRS};${CUDAToolkit_INCLUDE_DIR}")
endif()
set(HIP_RUNTIME_INCLUDE_DIRS "${HIP_ROOT_DIR}/include;${HIP_ROOT_DIR}/hcc/include" CACHE STRING "")
set(HIP_RUNTIME_COMPILE_FLAGS "${HIP_RUNTIME_COMPILE_FLAGS};${HIP_RUNTIME_DEFINES}")
# set(HIP_RUNTIME_LIBRARIES "${HIP_ROOT_DIR}/hcc/lib")
# set(HIP_RUNTIME_LIBRARIES "${HIP_ROOT_DIR}/hcc/lib")

set(_hip_compile_flags " ")
if (ENABLE_CLANG_HIP)
    set(_hip_compile_flags -x hip)
    # Using clang HIP, we need to construct a few CPP defines and compiler flags
    foreach(arch ${BLT_CLANG_HIP_ARCH})
        string(TOUPPER ${arch} UPARCH)
        string(TOLOWER ${arch} lowarch)
        list(APPEND _hip_compile_flags "--offload-arch=${lowarch}" "-D__HIP_ARCH_${UPARCH}__=1")
    endforeach(arch)
    
    # We need to pass rocm path as well, for certain bitcode libraries.
    # First see if we were given it, then see if it exists in the environment.
    # If not, don't try to guess but print a warning and hope the compiler knows where it is.
    if(NOT ROCM_PATH)
        if(DEFINED ENV{ROCM_PATH})
            set(ROCM_PATH "$ENV{ROCM_PATH}")
        endif()
    endif()

    if(DEFINED ROCM_PATH)
        list(APPEND _hip_compile_flags "--rocm-path=${ROCM_PATH}")
    else()
        message(WARNING "ROCM_PATH not found. Set this if the compiler can't find device bitcode libraries.")
    endif()

    message(STATUS "Clang HIP Enabled. HIP compile flags added: ${_hip_compile_flags}")

    # Fundamendally this is just the runtime includes with some extra compile flags
    blt_register_library(NAME      hip
                         COMPILE_FLAGS ${_hip_compile_flags}
                         INCLUDES  ${HIP_RUNTIME_INCLUDE_DIRS}
                         LIBRARIES ${HIP_RUNTIME_LIBRARIES}
                         TREAT_INCLUDES_AS_SYSTEM ON)

else()

    # depend on 'hip', if you need to use hip
    # headers, link to hip libs, and need to run your source
    # through a hip compiler (hipcc)
    blt_register_library(NAME      hip
                        INCLUDES  ${HIP_INCLUDE_DIRS}
                        LIBRARIES ${HIP_LIBRARIES}
                        TREAT_INCLUDES_AS_SYSTEM ON)
endif()


# depend on 'hip_runtime', if you only need to use hip
# headers or link to hip libs, but don't need to run your source
# through a hip compiler (hipcc)
blt_register_library(NAME          hip_runtime
                     INCLUDES      ${HIP_RUNTIME_INCLUDE_DIRS}
                     DEFINES       ${HIP_RUNTIME_DEFINES}
                     COMPILE_FLAGS ${HIP_RUNTIME_COMPILE_FLAGS}
                     LIBRARIES     ${HIP_RUNTIME_LIBRARIES}
                     TREAT_INCLUDES_AS_SYSTEM ON)
