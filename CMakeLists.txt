cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
include(FetchContent)
include(cmake/sys-detect.cmake)

set(NAME madrona-deps)
project(${NAME})

option(MADRONA_USE_PREBUILT "Use prebuilt dependency binaries" ON)

find_package(Git QUIET)

if (NOT DEFINED MADRONA_DEPS_VERSION)
    if (NOT Git_FOUND)
        message(FATAL_ERROR "Git not found, you must set explicit madrona-deps version to use (the short hash)")
    endif()

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        OUTPUT_VARIABLE MADRONA_DEPS_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()

if (MADRONA_USE_PREBUILT)
    if (IS_LINUX)
        set(DEPS_OS_NAME "ubuntu")
        set(DEPS_HASH "aa29fcacc1db89351bc3f1011935077f091e72885a9590d720fa0f0f9173db41")
    elseif (IS_MAC)
        set(DEPS_OS_NAME "macos")
        set(DEPS_HASH "b7dc635f287462bd86f137029742bd5a5d80f32a7d91a4fb7fb341160590cd2f")
    endif()

    set(DEPS_URL "https://github.com/shacklettbp/madrona-deps/releases/download/${MADRONA_DEPS_VERSION}/madrona-deps-${MADRONA_DEPS_VERSION}-${DEPS_OS_NAME}-latest.tar.zst")

    FetchContent_Declare(MadronaPrecompiledDeps
        URL ${DEPS_URL}
        URL_HASH SHA256=${DEPS_HASH}
    )

    FetchContent_MakeAvailable(MadronaPrecompiledDeps)

    set(DEP_ROOT ${madronaprecompileddeps_SOURCE_DIR})

    find_package(SDL2
        PATHS "${DEP_ROOT}/SDL"
        QUIET
        REQUIRED
        NO_DEFAULT_PATH
    )

    if (IS_LINUX OR IS_WINDOWS)
        add_library(madrona_vk_hdrs INTERFACE)
        target_include_directories(madrona_vk_hdrs
            INTERFACE "${DEP_ROOT}/vk_sdk/include"
        )
    endif()

    if (IS_LINUX)
        find_library(vk_loader_loc vulkan
            PATHS "${DEP_ROOT}/vk_sdk/lib"
            REQUIRED
            NO_DEFAULT_PATH
        )
        
        add_library(madrona_vk_loader SHARED IMPORTED)
        set_target_properties(madrona_vk_loader IMPORTED_LOCATION "${vk_loader_loc}")
    endif()
    
    find_library(MADRONA_DXC_LIB dxcompiler
        PATHS "${DEP_ROOT}/dxc/lib"
        REQUIRED
        NO_DEFAULT_PATH
    )
    set(MADRONA_DXC_INCLUDE_DIR "${DEP_ROOT}/dxc/include")
    
    find_library(MADRONA_SPIRV_CROSS_LIB spirv-cross-c-shared
        PATHS "${DEP_ROOT}/spirv_cross/lib"
        REQUIRED
        NO_DEFAULT_PATH
    )
    set(MADRONA_SPIRV_CROSS_INCLUDE_DIR "${DEP_ROOT}/spirv_cross/include")
    
else()
    find_package(SDL2 REQUIRED)

    if (IS_LINUX OR IS_WINDOWS)
        find_package(Vulkan REQUIRED)
        add_library(madrona_vk_hdrs INTERFACE)
        target_include_directories(madrona_vk_hdrs
            INTERFACE "${Vulkan_INCLUDE_DIRS}"
        )
    endif()

    if (IS_LINUX)
        add_library(madrona_vk_loader INTERFACE)
        target_link_libraries(madrona_vk_loader INTERFACE
            ${Vulkan_LIBRARIES}
        )
    endif()

    find_library(MADRONA_DXC_LIB dxcompiler REQUIRED
        HINTS "$ENV{VULKAN_SDK}/lib")
    find_path(MADRONA_DXC_INCLUDE_DIR dxc/dxcapi.h REQUIRED
        HINTS "$ENV{VULKAN_SDK}/include")

    find_library(MADRONA_SPIRV_CROSS_LIB spirv-cross-c-shared REQUIRED
        HINTS "$ENV{VULKAN_SDK}/lib")
    find_path(MADRONA_SPIRV_CROSS_INCLUDE_DIR spirv_cross/spirv_cross.hpp REQUIRED
        HINTS "$ENV{VULKAN_SDK}/include")
endif()

add_library(madrona_dxc SHARED IMPORTED)
set_target_properties(madrona_dxc PROPERTIES IMPORTED_LOCATION "${MADRONA_DXC_LIB}")
target_include_directories(madrona_dxc
    INTERFACE "${MADRONA_DXC_INCLUDE_DIR}"
)

add_library(madrona_spirv_cross SHARED IMPORTED)
set_target_properties(madrona_spirv_cross PROPERTIES IMPORTED_LOCATION "${MADRONA_SPIRV_CROSS_LIB}")
target_include_directories(madrona_spirv_cross
    INTERFACE "${MADRONA_SPIRV_CROSS_INCLUDE_DIR}"
)
