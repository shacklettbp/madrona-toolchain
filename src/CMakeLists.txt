cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
set(NAME madrona-deps-compile)
project(${NAME})

include(FetchContent)
include(ExternalProject)

get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
include(${PARENT_DIR}/cmake/sys-detect.cmake)

include(versions.cmake)

if (IS_MAC)
    set(CMAKE_OSX_ARCHITECTURES arm64;x86_64)
endif()

set (SDL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/SDL")
set (SDL_INSTALL "${SDL_PREFIX}/install")

list(APPEND SDL_ARGS
    "-DCMAKE_INSTALL_PREFIX=${SDL_PREFIX}/install"
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
    "-DSDL_SHARED=ON"
    "-DSDL_STATIC=OFF"
    "-DSDL_ASSERTIONS=release"
    "-DSDL_WAYLAND=OFF"
    "-DSDL_KMSDRM=OFF"
    "-DSDL_OPENGLES=OFF"
    "-DSDL_DISKAUDIO=OFF"
)

if (IS_LINUX)
    list(APPEND SDL_ARGS
        "-DSDL_X11=ON"
        "-DSDL_OPENGL=ON"
        "-DSDL_VULKAN=ON"
    )
elseif (IS_MAC)
    string(REPLACE ";" "$<SEMICOLON>" CMAKE_OSX_ARCHITECTURES_ "${CMAKE_OSX_ARCHITECTURES}")
    list(APPEND SDL_ARGS
        "-DSDL_COCOA=ON"
        "-DSDL_METAL=ON"
        "-DSDL_OPENGL=OFF"
        "-DSDL_VULKAN=OFF"
        "-DSDL_RENDER_METAL=OFF"
        "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_}"
    )
endif()

ExternalProject_Add(SDL
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG "${SDL_VERSION}"
    GIT_SHALLOW ON
    PREFIX "${SDL_PREFIX}"
    INSTALL_DIR "${SDL_INSTALL}"
    CMAKE_ARGS ${SDL_ARGS}
)

install(DIRECTORY "${SDL_INSTALL}/include/SDL2"
    DESTINATION SDL/include
)

install(DIRECTORY ${SDL_INSTALL}/lib/
    DESTINATION SDL/lib
    FILES_MATCHING
        PATTERN *
        PATTERN *pkgconfig* EXCLUDE
)

install(FILES ${spirv_cross_libs}
    DESTINATION spirv_cross/lib
)

find_package(Python 3.6 COMPONENTS Interpreter)

# Vulkan SDK fetch. All platforms use the Vulkan SDK at least for the pre-compiled copy of DXC
if (IS_LINUX)
    set(VULKAN_URL "https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/linux/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz")
    set(VULKAN_HASH "488df47afe317bc2cd1f03305f19e5ad7b58db12738f8ba097042ba57d758c9d")
    set(VULKAN_NO_EXTRACT OFF)
elseif (IS_MAC)
    set(VULKAN_DMG_NAME "vulkansdk-macos-${VULKAN_SDK_VERSION}.dmg")
    set(VULKAN_URL "https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/mac/${VULKAN_DMG_NAME}")
    set(VULKAN_HASH "59f08f86672ff8f0a452c309883bf6bf46ce70e0d01a86c23a044e497c06dd17")
    set(VULKAN_NO_EXTRACT ON)
endif()

FetchContent_Declare(VulkanSDK
    URL ${VULKAN_URL}
    URL_HASH SHA256=${VULKAN_HASH}
    DOWNLOAD_NO_EXTRACT ${VULKAN_NO_EXTRACT}
)

FetchContent_MakeAvailable(VulkanSDK)

if (IS_LINUX)
    set(VULKAN_SDK_ROOT "${vulkansdk_SOURCE_DIR}/x86_64")
elseif (IS_MAC)
    execute_process(
        COMMAND "${Python_EXECUTABLE}" "${PARENT_DIR}/scripts/extract_mac_vulkan_sdk.py" "${vulkansdk_SOURCE_DIR}/${VULKAN_DMG_NAME}" "${VULKAN_HASH}" "${vulkansdk_SOURCE_DIR}" "${sevenzip_SOURCE_DIR}/7zz"
        COMMAND_ERROR_IS_FATAL ANY
    )

    set(VULKAN_SDK_ROOT "${vulkansdk_SOURCE_DIR}/macOS")
endif()

if (IS_LINUX OR IS_WINDOWS)
    install(DIRECTORY ${VULKAN_SDK_ROOT}/include/vulkan
        DESTINATION vk_sdk/include/
    )
endif()

if (IS_LINUX)
    file(GLOB vk_loader_libs ${VULKAN_SDK_ROOT}/lib/libvulkan*)

    install(FILES ${vk_loader_libs}
        DESTINATION vk_sdk/lib
    )
endif()

install(DIRECTORY ${VULKAN_SDK_ROOT}/include/dxc
    DESTINATION dxc/include/
)

file(GLOB dxc_libs ${VULKAN_SDK_ROOT}/lib/*dxcompiler*)

install(FILES ${dxc_libs}
    DESTINATION dxc/lib
)

install(DIRECTORY ${VULKAN_SDK_ROOT}/include/spirv_cross
    DESTINATION spirv_cross/include/
)

file(GLOB spirv_cross_libs ${VULKAN_SDK_ROOT}/lib/*spirv-cross-c-shared*)

install(FILES ${spirv_cross_libs}
    DESTINATION spirv_cross/lib
)
