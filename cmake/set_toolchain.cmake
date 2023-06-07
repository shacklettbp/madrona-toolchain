include(FetchContent)

option(MADRONA_USE_TOOLCHAIN "Use prebuilt toolchain binaries" ON)
if (NOT MADRONA_USE_TOOLCHAIN)
    return()
endif()

function(madrona_setup_toolchain)
    cmake_path(GET CMAKE_CURRENT_FUNCTION_LIST_DIR PARENT_PATH TOOLCHAIN_REPO)

    include("${TOOLCHAIN_REPO}/cmake/current-hashes.cmake")
    include("${TOOLCHAIN_REPO}/cmake/sys-detect.cmake")

    find_package(Git QUIET)
    if (NOT DEFINED MADRONA_TOOLCHAIN_VERSION)
        if (NOT Git_FOUND)
            message(FATAL_ERROR "git not found, you must set MADRONA_TOOLCHAIN_VERSION to the short hash of the toolchain commit")
        endif()
    
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
            WORKING_DIRECTORY "${TOOLCHAIN_REPO}"
            OUTPUT_VARIABLE MADRONA_TOOLCHAIN_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    if (MADRONA_LINUX)
        set(TOOLCHAIN_OS_NAME "linux")
        if (NOT DEFINED MADRONA_TOOLCHAIN_HASH)
            set(MADRONA_TOOLCHAIN_HASH "${MADRONA_TOOLCHAIN_LINUX_HASH}")
        endif()
    elseif (MADRONA_MACOS)
        set(TOOLCHAIN_OS_NAME "mac")
        if (NOT DEFINED MADRONA_TOOLCHAIN_HASH)
            set(MADRONA_TOOLCHAIN_HASH "${MADRONA_TOOLCHAIN_MACOS_HASH}")
        endif()
    endif()
    
    set(DEPS_URL "https://github.com/shacklettbp/madrona-toolchain/releases/download/${MADRONA_TOOLCHAIN_VERSION}/madrona-toolchain-${MADRONA_TOOLCHAIN_VERSION}-${TOOLCHAIN_OS_NAME}.tar.xz")
    
    FetchContent_Declare(MadronaBundledToolchain
        URL ${DEPS_URL}
        URL_HASH SHA256=${MADRONA_TOOLCHAIN_HASH}
        DOWNLOAD_DIR "${TOOLCHAIN_REPO}/download"
        DOWNLOAD_NAME cur.tar # Can't name it .tar.xz or CMake will ignore
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_DIR "${TOOLCHAIN_REPO}/bundled-toolchain"
        STAMP_DIR "${TOOLCHAIN_REPO}/download/timestamps"
    )
    
    FetchContent_MakeAvailable(MadronaBundledToolchain)
    
    if (MADRONA_TOOLCHAIN_ROOT_OVERRIDE)
        set(TOOLCHAIN_ROOT "${MADRONA_TOOLCHAIN_ROOT_OVERRIDE}")
    else()
        set(TOOLCHAIN_ROOT "${madronabundledtoolchain_SOURCE_DIR}")
    endif()

    set(TOOLCHAIN_SYSROOT "${TOOLCHAIN_ROOT}/toolchain")
    
    if (MADRONA_MACOS)
        file(GLOB TOOLCHAIN_SYSROOT "${TOOLCHAIN_SYSROOT}/Toolchains/LLVM*.xctoolchain/usr")
    endif()

    set(CMAKE_C_COMPILER "${TOOLCHAIN_SYSROOT}/bin/clang" CACHE STRING "")
    set(CMAKE_CXX_COMPILER "${TOOLCHAIN_SYSROOT}/bin/clang++" CACHE STRING "")

    # On macos, universal builds with this toolchain will be broken due to
    # llvm-ranlib not working with univeral libraries. /usr/bin/ar is picked
    # by default by cmake, but the compiler ranlib is still used, breaking
    # static libraries. 
    # One option is to force /usr/bin/ranlib on macos.
    # The better option is to do what LLVM itself does, which is to just use
    # libtool on macos for building static libraries since it is more
    # optimized anyway: https://reviews.llvm.org/D19611. llvm-libtool
    # correctly handles universal binaries
    if (MADRONA_MACOS)
        set(CMAKE_CXX_CREATE_STATIC_LIBRARY "\"${TOOLCHAIN_PATH}/bin/llvm-libtool-darwin\" -static -no_warning_for_no_symbols -o <TARGET> <LINK_FLAGS> <OBJECTS>")
        # need to disable ranlib or it will run after libtool
        set(CMAKE_RANLIB "")
    endif ()
endfunction()

madrona_setup_toolchain()
unset(madrona_setup_toolchain)
