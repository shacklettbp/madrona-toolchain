cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
set(NAME madrona-toolchain-compile)

if (APPLE)
    set(MADRONA_TOOLCHAIN_MACOS_ARCH "" CACHE STRING "macOS compiler host architecture")
    if (NOT MADRONA_TOOLCHAIN_MACOS_ARCH)
        message(FATAL_ERROR "Must specify macOS host architecture")
    endif()

    set(CMAKE_OSX_ARCHITECTURES "${MADRONA_TOOLCHAIN_MACOS_ARCH}" CACHE STRING "")
    list(JOIN CMAKE_OSX_ARCHITECTURES "$<SEMICOLON>" EXT_OSX_ARCHITECTURES)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "")
endif()

project(${NAME} LANGUAGES C CXX)

if (APPLE)
  execute_process(COMMAND xcrun --show-sdk-path OUTPUT_VARIABLE CMAKE_OSX_SYSROOT 
    COMMAND_ERROR_IS_FATAL ANY
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

include(FetchContent)
include(ExternalProject)

find_package(Python 3.6 COMPONENTS Interpreter)
find_package(Patch REQUIRED)

include(versions.cmake)

set(NCURSES_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/ncurses")
set(NCURSES_SRC "${NCURSES_PREFIX}/sources")
set(NCURSES_INSTALL "${NCURSES_PREFIX}/install")

set(NCURSES_CFLAGS "-O3 -fPIC")
set(NCURSES_CXXFLAGS "-O3 -fPIC")
set(NCURSES_CPPFLAGS)
if (APPLE)
    set(NCURSES_CFLAGS "${NCURSES_CFLAGS} -arch ${MADRONA_TOOLCHAIN_MACOS_ARCH} -isysroot${CMAKE_OSX_SYSROOT} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    set(NCURSES_CXXFLAGS "${NCURSES_CXXFLAGS} -arch ${MADRONA_TOOLCHAIN_MACOS_ARCH} -isysroot${CMAKE_OSX_SYSROOT} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    set(NCURSES_CPPFLAGS "${NCURSES_CPPFLAGS} -isysroot${CMAKE_OSX_SYSROOT}")
endif()

ExternalProject_Add(ncurses
    URL "https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
    URL_HASH SHA256=${NCURSES_HASH}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    PREFIX "${NCURSES_PREFIX}"
    SOURCE_DIR "${NCURSES_SRC}"
    INSTALL_DIR "${NCURSES_INSTALL}"
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E env CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} CFLAGS=${NCURSES_CFLAGS} CPPFLAGS=${NCURSES_CPPFLAGS} CXXFLAGS=${NCURSES_CXXFLAGS} "${NCURSES_SRC}/configure" --prefix=/usr --with-termlib --enable-widec --without-debug --without-cxx-binding --without-ada
    BUILD_COMMAND
        make
    INSTALL_COMMAND
        make DESTDIR=${NCURSES_INSTALL} install
)

ExternalProject_Add_Step(ncurses copy_tinfo
    COMMAND 
        ${CMAKE_COMMAND} -E copy ${NCURSES_INSTALL}/usr/lib/libtinfow.a ${NCURSES_INSTALL}/usr/lib/libtinfo.a
    DEPENDEES
        install
    BYPRODUCTS
        ${NCURSES_INSTALL}/lib/libtinfo.a
)

set(ZSTD_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/zstd")
set(ZSTD_INSTALL "${ZSTD_PREFIX}/install")

ExternalProject_Add(zstd
    GIT_REPOSITORY https://github.com/facebook/zstd.git
    GIT_TAG "${ZSTD_VERSION}"
    GIT_SHALLOW ON
    PREFIX "${ZSTD_PREFIX}"
    INSTALL_DIR "${ZSTD_INSTALL}"
    CMAKE_ARGS
        "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
        "-DCMAKE_INSTALL_PREFIX=${ZSTD_INSTALL}"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
        "-DCMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        "-DZSTD_BUILD_SHARED=OFF"
        "-DZSTD_BUILD_STATIC=ON"
        "-DZSTD_MULTITHREAD_SUPPORT=ON"
        "-DZSTD_BUILD_PROGRAMS=OFF"
    SOURCE_SUBDIR build/cmake
)

set(ZLIB_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/zlib")
set(ZLIB_INSTALL "${ZLIB_PREFIX}/install")

list(APPEND ZLIB_CMAKE_ARGS
    "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_INSTALL_PREFIX=${ZLIB_INSTALL}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DCMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
    "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
)

ExternalProject_Add(zlib
    URL "https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz"
    URL_HASH SHA256=${ZLIB_HASH}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    PREFIX "${ZLIB_PREFIX}"
    INSTALL_DIR "${ZLIB_INSTALL}"
    CMAKE_ARGS ${ZLIB_CMAKE_ARGS}
)

FetchContent_Declare(llvm_project
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz
    URL_HASH SHA256=${LLVM_HASH}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
)
FetchContent_MakeAvailable(llvm_project)

set(LLVM_TOOLCHAIN_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/toolchain")
set(LLVM_TOOLCHAIN_BUILD "${LLVM_TOOLCHAIN_PREFIX}/build")
set(LLVM_TOOLCHAIN_INSTALL "${LLVM_TOOLCHAIN_PREFIX}/install")

list(APPEND LLVM_TOOLCHAIN_ARGS
    "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=${LLVM_TOOLCHAIN_INSTALL}"
    "-DCMAKE_PREFIX_PATH=${NCURSES_INSTALL}/usr/$<SEMICOLON>${ZSTD_INSTALL}$<SEMICOLON>${ZLIB_INSTALL}"
    "-DZLIB_USE_STATIC_LIBS=ON"
    "-DCMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
    "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
    "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
    "-DBOOTSTRAP_CMAKE_PREFIX_PATH=${NCURSES_INSTALL}/usr/$<SEMICOLON>${ZSTD_INSTALL}$<SEMICOLON>${ZLIB_INSTALL}"
    "-DBOOTSTRAP_CMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
    "-DBOOTSTRAP_CMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
    "-DBOOTSTRAP_CMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
    "-C ${CMAKE_CURRENT_LIST_DIR}/llvm-stage1.cmake"
)

if (APPLE)
    list(APPEND LLVM_INSTALL_TARGETS 
        stage2-install-xcode-toolchain
        stage2-install-distribution-toolchain
    )
else()
    list(APPEND LLVM_INSTALL_TARGETS 
        stage2-install-distribution-stripped
    )
endif()

# There seems to be a race condition in the clang bootstrap process due to
# improper dependencies in LLVM's internal use of ExternalProject_Add. 
# Forcing the generator to Ninja  fixes it because Ninja can't work on
# multiple ExternalProjects in parallel
ExternalProject_Add(llvm_toolchain
    DEPENDS zstd zlib ncurses
    SOURCE_DIR "${llvm_project_SOURCE_DIR}"
    PREFIX "${LLVM_TOOLCHAIN_PREFIX}"
    BINARY_DIR "${LLVM_TOOLCHAIN_BUILD}"
    INSTALL_DIR "${LLVM_TOOLCHAIN_INSTALL}"
    CMAKE_GENERATOR Ninja
    CMAKE_ARGS
        ${LLVM_TOOLCHAIN_ARGS}
    SOURCE_SUBDIR llvm
    USES_TERMINAL_BUILD true
    BUILD_COMMAND
        ninja -C "${LLVM_TOOLCHAIN_BUILD}" stage2-distribution
    INSTALL_COMMAND 
        ninja -C "${LLVM_TOOLCHAIN_BUILD}" ${LLVM_INSTALL_TARGETS}
)

install(DIRECTORY ${LLVM_TOOLCHAIN_INSTALL}/
    DESTINATION .
    USE_SOURCE_PERMISSIONS
)
