cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)

set(NAME madrona-toolchain)
project(${NAME})

include(FetchContent)
include(cmake/sys-detect.cmake)
include(cmake/current-hashes.cmake)

option(MADRONA_USE_TOOLCHAIN "Use prebuilt toolchain binaries" ON)

find_package(Git QUIET)

if (MADRONA_USE_BUNDLED)
    if (NOT DEFINED MADRONA_TOOLCHAIN_VERSION)
        if (NOT Git_FOUND)
            message(FATAL_ERROR "Git not found, you must set explicit madrona-toolchain version to use (the short hash)")
        endif()
    
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            OUTPUT_VARIABLE MADRONA_TOOLCHAIN_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    if (MADRONA_LINUX)
        set(DEPS_OS_NAME "linux")
        if (NOT DEFINED MADRONA_DEPS_HASH)
            set(MADRONA_DEPS_HASH "${MADRONA_DEPS_LINUX_HASH}")
        endif()
    elseif (MADRONA_MACOS)
        set(DEPS_OS_NAME "mac")
        if (NOT DEFINED MADRONA_DEPS_HASH)
            set(MADRONA_DEPS_HASH "${MADRONA_DEPS_MACOS_HASH}")
        endif()
    endif()

    set(DEPS_URL "https://github.com/shacklettbp/madrona-deps/releases/download/${MADRONA_DEPS_VERSION}/madrona-deps-${MADRONA_DEPS_VERSION}-${DEPS_OS_NAME}.tar.zst")

    FetchContent_Declare(MadronaPrecompiledDeps
        URL ${DEPS_URL}
        URL_HASH SHA256=${MADRONA_DEPS_HASH}
        DOWNLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/download"
        DOWNLOAD_NAME cur.tar # Can't name it .tar.zst or CMake will ignore
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    FetchContent_MakeAvailable(MadronaPrecompiledDeps)

    set(DEP_ROOT ${madronaprecompileddeps_SOURCE_DIR})

    add_library(madrona_libcxx INTERFACE)
    if (MADRONA_MACOS OR MADRONA_LINUX)
        target_compile_options(madrona_libcxx INTERFACE
            -nostdinc++ -nostdlib++
        )
        target_link_options(madrona_libcxx INTERFACE
            -nostdlib++ -rtlib=compiler-rt
        )
        target_include_directories(madrona_libcxx SYSTEM INTERFACE
            $<BUILD_INTERFACE:${DEP_ROOT}/libcxx/include/c++/v1>
        )

        find_library(MADRONA_BUNDLED_LIBCXX c++
            PATHS "${DEP_ROOT}/libcxx/lib"
            REQUIRED
            NO_DEFAULT_PATH
        )

        target_link_libraries(madrona_libcxx INTERFACE
            ${MADRONA_BUNDLED_LIBCXX}
        )
    endif()

    if (MADRONA_LINUX)
        find_package(SDL2
            PATHS "${DEP_ROOT}/SDL"
            QUIET
            REQUIRED
            NO_DEFAULT_PATH
        )
    endif()

    if (MADRONA_LINUX OR MADRONA_WINDOWS)
        add_library(madrona_vk_hdrs INTERFACE)
        target_include_directories(madrona_vk_hdrs
            INTERFACE "${DEP_ROOT}/vk_sdk/include"
        )

        find_library(vk_loader_loc vulkan
            PATHS "${DEP_ROOT}/vk_sdk/lib"
            REQUIRED
            NO_DEFAULT_PATH
        )
        
        add_library(madrona_vk_loader SHARED IMPORTED)
        set_target_properties(madrona_vk_loader PROPERTIES IMPORTED_LOCATION "${vk_loader_loc}")

        add_library(madrona_vk_layers INTERFACE)
        target_compile_definitions(madrona_vk_layers INTERFACE
            "-DMADRONA_VK_LAYERS_DIR=${DEP_ROOT}/vk_sdk/layers"
        )
    endif()
    
    find_library(MADRONA_DXC_LIB dxcompiler
        PATHS "${DEP_ROOT}/dxc/lib"
        REQUIRED
        NO_DEFAULT_PATH
    )
    set(MADRONA_DXC_INCLUDE_DIR "${DEP_ROOT}/dxc/include")
    
    if (MADRONA_MACOS OR MADRONA_IOS)
        find_library(MADRONA_SPIRV_CROSS_LIB spirv-cross-c-shared
            PATHS "${DEP_ROOT}/spirv_cross/lib"
            REQUIRED
            NO_DEFAULT_PATH
        )
        set(MADRONA_SPIRV_CROSS_INCLUDE_DIR "${DEP_ROOT}/spirv_cross/include")

        add_library(madrona_metal_cpp INTERFACE)
        target_include_directories(madrona_metal_cpp
            INTERFACE "${DEP_ROOT}/metal-cpp/include"
        )
    endif ()
    
else()
    add_library(madrona_libcxx INTERFACE)

    if (MADRONA_LINUX)
        find_package(SDL2 REQUIRED)
    endif()

    if (MADRONA_LINUX OR MADRONA_WINDOWS)
        find_package(Vulkan REQUIRED)
        add_library(madrona_vk_hdrs INTERFACE)
        target_include_directories(madrona_vk_hdrs
            INTERFACE "${Vulkan_INCLUDE_DIRS}"
        )
    endif()

    if (MADRONA_LINUX)
        add_library(madrona_vk_loader INTERFACE)
        target_link_libraries(madrona_vk_loader INTERFACE
            ${Vulkan_LIBRARIES}
        )
    endif()

    find_library(MADRONA_DXC_LIB dxcompiler REQUIRED
        HINTS "$ENV{VULKAN_SDK}/lib")
    find_path(MADRONA_DXC_INCLUDE_DIR dxc/dxcapi.h REQUIRED
        HINTS "$ENV{VULKAN_SDK}/include")

    if (MADRONA_MACOS OR MADRONA_IOS)
        find_library(MADRONA_SPIRV_CROSS_LIB spirv-cross-c-shared REQUIRED
            HINTS "$ENV{VULKAN_SDK}/lib")
        find_path(MADRONA_SPIRV_CROSS_INCLUDE_DIR spirv_cross/spirv_cross.hpp REQUIRED
            HINTS "$ENV{VULKAN_SDK}/include")

        if (NOT DEFINED MADRONA_METAL_CPP_DIR)
            message(FATAL_ERROR "Must define MADRONA_METAL_CPP_DIR on Mac when not using bundled dependencies")
        endif()

        add_library(madrona_metal_cpp INTERFACE)
        target_include_directories(madrona_metal_cpp INTERFACE
            ${MADRONA_METAL_CPP_DIR}
        )
    endif()
endif()

# FIXME proper install support
install(TARGETS madrona_libcxx
    EXPORT madronaLibCXXTarget
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}
)

install(EXPORT madronaLibCXXTarget
    DESTINATION ${CMAKE_INSTALL_PREFIX}
)

if (MADRONA_LINUX)
    add_library(madrona_sdl2 INTERFACE)
    target_link_libraries(madrona_sdl2
        INTERFACE SDL2::SDL2
    )
endif()

add_library(madrona_dxc SHARED IMPORTED GLOBAL)
set_target_properties(madrona_dxc PROPERTIES IMPORTED_LOCATION "${MADRONA_DXC_LIB}")
target_include_directories(madrona_dxc
    INTERFACE "${MADRONA_DXC_INCLUDE_DIR}"
)

if (MADRONA_MACOS)
    add_library(madrona_spirv_cross SHARED IMPORTED GLOBAL)
    set_target_properties(madrona_spirv_cross PROPERTIES IMPORTED_LOCATION "${MADRONA_SPIRV_CROSS_LIB}")
    target_include_directories(madrona_spirv_cross
        INTERFACE "${MADRONA_SPIRV_CROSS_INCLUDE_DIR}"
    )
endif ()
