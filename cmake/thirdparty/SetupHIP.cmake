# Copyright (c) 2017-2021, Lawrence Livermore National Security, LLC and
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
if ( IS_DIRECTORY "${HIP_ROOT_DIR}/hcc/include" ) # this path only exists on older rocm installs
        set(HIP_RUNTIME_INCLUDE_DIRS "${HIP_ROOT_DIR}/include;${HIP_ROOT_DIR}/hcc/include" CACHE STRING "")
else()
        set(HIP_RUNTIME_INCLUDE_DIRS "${HIP_ROOT_DIR}/include" CACHE STRING "")
endif()
set(HIP_RUNTIME_COMPILE_FLAGS "${HIP_RUNTIME_COMPILE_FLAGS};-Wno-unused-parameter")

# depend on 'hip', if you need to use hip
# headers, link to hip libs, and need to run your source
# through a hip compiler (hipcc)
# This is currently used only as an indicator for blt_add_hip* -- FindHIP/hipcc will handle resolution
# of all required HIP-related includes/libraries/flags.
if (ENABLE_CLANG_HIP)
    blt_import_library(NAME      hip
                       COMPILE_FLAGS -x;hip
                       LINK_FLAGS -lamdhip64;-L${HIP_ROOT_DIR}/lib)
else()
    blt_import_library(NAME      hip)
endif()

# depend on 'hip_runtime', if you only need to use hip
# headers or link to hip libs, but don't need to run your source
# through a hip compiler (hipcc)
blt_import_library(NAME          hip_runtime
                   INCLUDES      ${HIP_RUNTIME_INCLUDE_DIRS}
                   DEFINES       ${HIP_RUNTIME_DEFINES}
                   COMPILE_FLAGS ${HIP_RUNTIME_COMPILE_FLAGS}
                   LINK_FLAGS -lamdhip64;-L${HIP_ROOT_DIR}/lib
                   TREAT_INCLUDES_AS_SYSTEM ON
                   EXPORTABLE    ${BLT_EXPORT_THIRDPARTY})
