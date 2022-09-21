cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
set(NAME madrona-deps-compile)
project(${NAME})

include(FetchContent)
include(ExternalProject)

get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
include(${PARENT_DIR}/cmake/sys-detect.cmake)

include(versions.cmake)

if (MADRONA_MACOS)
    set(CMAKE_OSX_ARCHITECTURES arm64;x86_64)
endif()

if (MADRONA_LINUX)
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
        "-DSDL_X11=ON"
        "-DSDL_OPENGL=ON"
        "-DSDL_VULKAN=ON"
    )

    ExternalProject_Add(SDL
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG "${SDL_VERSION}"
        GIT_SHALLOW ON
        PREFIX "${SDL_PREFIX}"
        INSTALL_DIR "${SDL_INSTALL}"
        CMAKE_ARGS ${SDL_ARGS}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
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
endif()

install(FILES ${spirv_cross_libs}
    DESTINATION spirv_cross/lib
)

find_package(Python 3.6 COMPONENTS Interpreter)

# Vulkan SDK fetch. All platforms use the Vulkan SDK at least for the pre-compiled copy of DXC
if (MADRONA_LINUX)
    set(VULKAN_URL "https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/linux/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz")
    set(VULKAN_HASH "47c3a5bd033abf0fc2a9df113a8b7fb829a51d86d234385bd742310afc116316")
    set(VULKAN_NO_EXTRACT OFF)
elseif (MADRONA_MACOS)
    set(VULKAN_DMG_NAME "vulkansdk-macos-${VULKAN_SDK_VERSION}.dmg")
    set(VULKAN_URL "https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/mac/${VULKAN_DMG_NAME}")
    set(VULKAN_HASH "35e35e8ac0fa13fa90c35253d5160f147ac99b39e296f6502a9dce9f41795838")
    set(VULKAN_NO_EXTRACT ON)
endif()

FetchContent_Declare(VulkanSDK
    URL ${VULKAN_URL}
    URL_HASH SHA256=${VULKAN_HASH}
    DOWNLOAD_NO_EXTRACT ${VULKAN_NO_EXTRACT}
)

FetchContent_MakeAvailable(VulkanSDK)

if (MADRONA_LINUX)
    set(VULKAN_SDK_ROOT "${vulkansdk_SOURCE_DIR}/x86_64")
elseif (MADRONA_MACOS)
    execute_process(
        COMMAND "${Python_EXECUTABLE}" "${PARENT_DIR}/scripts/extract_mac_vulkan_sdk.py" "${vulkansdk_SOURCE_DIR}/${VULKAN_DMG_NAME}" "${VULKAN_HASH}" "${vulkansdk_SOURCE_DIR}" "${sevenzip_SOURCE_DIR}/7zz"
        COMMAND_ERROR_IS_FATAL ANY
    )

    set(VULKAN_SDK_ROOT "${vulkansdk_SOURCE_DIR}/macOS")
endif()

if (MADRONA_LINUX OR MADRONA_WINDOWS)
    install(DIRECTORY ${VULKAN_SDK_ROOT}/include/vulkan
        DESTINATION vk_sdk/include/
    )
endif()

if (MADRONA_LINUX)
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
