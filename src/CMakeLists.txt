cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
include(${PARENT_DIR}/cmake/sys-detect.cmake)

set(NAME madrona-toolchain-compile)

if (MADRONA_MACOS)
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    list(JOIN CMAKE_OSX_ARCHITECTURES "$<SEMICOLON>" EXT_OSX_ARCHITECTURES)
endif()

project(${NAME})

include(FetchContent)
include(ExternalProject)

find_package(Python 3.6 COMPONENTS Interpreter)

include(versions.cmake)

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
        "-DCMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
        "-DZSTD_BUILD_SHARED=OFF"
        "-DZSTD_BUILD_STATIC=ON"
        "-DZSTD_MULTITHREAD_SUPPORT=ON"
        "-DZSTD_BUILD_PROGRAMS=OFF"
    SOURCE_SUBDIR build/cmake
)

list(APPEND LLVM_COMMON_ARGS
    "-DCMAKE_BUILD_TYPE=Release"
)

set(LLVM_C_FLAGS "")
set(LLVM_CXX_FLAGS "")

if (MADRONA_X64)
    set(LLVM_C_FLAGS "${LLVM_C_FLAGS} -march=x86-64-v3")
    set(LLVM_CXX_FLAGS "${LLVM_CXX_FLAGS} -march=x86-64-v3")
endif()

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

# libcxx is built without exception & rtti support, so these flags are
# required during stage2 otherwise the stage2 binaries will fail to link
set(LLVM_STAGE2_CXX_FLAGS "${LLVM_CXX_FLAGS} -fno-stack-protector -fno-exceptions -fno-rtti")
set(LLVM_STAGE2_LINKER_FLAGS "${LLVM_CXX_FLAGS} -fno-stack-protector -fno-exceptions -fno-rtti")

if (APPLE)
    # On Darwin, the custom libc++'s path isn't in the default search path, but
    # headers are. This results in a weird situation with the custom libc++ ABI
    # namespace where the stage1 compiler is broken due to building libraries
    # with the custom headers but linking system libc++. The search path is
    # hardcoded for the linker here so the stage2 build succeeds.
    # Known LLVM bug: https://reviews.llvm.org/D45639
    set(LLVM_STAGE2_LINKER_FLAGS "${LLVM_STAGE2_LINKER_FLAGS} -L${LLVM_TOOLCHAIN_BUILD}/lib")
endif()

list(APPEND LLVM_TOOLCHAIN_ARGS
    "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_C_FLAGS=${LLVM_C_FLAGS}"
    "-DCMAKE_CXX_FLAGS=${LLVM_CXX_FLAGS}"
    "-DCMAKE_INSTALL_PREFIX=${LLVM_TOOLCHAIN_INSTALL}"
    "-DCMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
    "-Dzstd_INCLUDE_DIR=${ZSTD_INSTALL}/include"
    "-Dzstd_LIBRARY=${ZSTD_INSTALL}/lib/libzstd.a"
    "-DBOOTSTRAP_CMAKE_C_FLAGS=${LLVM_C_FLAGS}"
    "-DBOOTSTRAP_CMAKE_CXX_FLAGS=${LLVM_STAGE2_CXX_FLAGS}"
    "-DBOOTSTRAP_CMAKE_EXE_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_SHARED_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_MODULE_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_OSX_ARCHITECTURES=${EXT_OSX_ARCHITECTURES}"
    "-DBOOTSTRAP_zstd_INCLUDE_DIR=${ZSTD_INSTALL}/include"
    "-DBOOTSTRAP_zstd_LIBRARY=${ZSTD_INSTALL}/lib/libzstd.a"
    "-C ${CMAKE_CURRENT_LIST_DIR}/llvm-stage1.cmake"
)

set(LLVM_INSTALL_TARGETS stage2-install-distribution-stripped )

if (MADRONA_X64 AND MADRONA_LINUX)
    # Force to pc-linux as oppposed to unknown-linux
    LIST(APPEND LLVM_TOOLCHAIN_ARGS 
        "-DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-pc-linux-gnu"
    )

    set(LLVM_INSTALL_TARGETS "${LLVM_INSTALL_TARGETS} stage2-install-xcode-toolchain")
endif()

# There seems to be a race condition in the clang bootstrap process due to
# improper dependencies in LLVM's internal use of ExternalProject_Add. 
# Forcing the generator to Ninja  fixes it because Ninja can't work on
# multiple ExternalProjects in parallel
ExternalProject_Add(llvm_toolchain
    DEPENDS zstd
    SOURCE_DIR "${llvm_project_SOURCE_DIR}"
    PREFIX "${LLVM_TOOLCHAIN_PREFIX}"
    BINARY_DIR "${LLVM_TOOLCHAIN_BUILD}"
    INSTALL_DIR "${LLVM_TOOLCHAIN_INSTALL}"
    CMAKE_GENERATOR Ninja
    CMAKE_ARGS
        ${LLVM_COMMON_ARGS}
        ${LLVM_TOOLCHAIN_ARGS}
    SOURCE_SUBDIR llvm
    BUILD_COMMAND
        ninja -C "${LLVM_TOOLCHAIN_BUILD}" stage2-distribution
    INSTALL_COMMAND 
    ninja -C "${LLVM_TOOLCHAIN_BUILD}" ${LLVM_INSTALL_TARGETS}
)

#ExternalProject_Add(libcxx
#    DEPENDS llvm_toolchain
#    SOURCE_DIR "${llvm_project_SOURCE_DIR}"
#    PREFIX "${LIBCXX_PREFIX}"
#    BINARY_DIR "${LIBCXX_BUILD}"
#    INSTALL_DIR "${LIBCXX_INSTALL}"
#    CMAKE_ARGS
#        ${LLVM_COMMON_ARGS}
#        ${LLVM_LIBCXX_ARGS}
#    SOURCE_SUBDIR runtimes
#    BUILD_COMMAND ${CMAKE_COMMAND} --build "${LIBCXX_BUILD}" --target cxx --target cxxabi --target unwind
#)
#
#set(LIBCXX_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/libcxx")
#set(LIBCXX_BUILD "${LIBCXX_PREFIX}/build")
#set(LIBCXX_INSTALL "${LIBCXX_PREFIX}/install")
#
#list(APPEND LLVM_LIBCXX_ARGS
#    "-DCMAKE_C_FLAGS=${LLVM_C_FLAGS}"
#    "-DCMAKE_CXX_FLAGS=${LLVM_CXX_FLAGS}"
#    "-DCMAKE_INSTALL_PREFIX=${LIBCXX_INSTALL}"
#    "-DLIBCXX_ENABLE_SHARED=ON"
#    "-DLIBCXX_ENABLE_STATIC=ON"
#    "-DLIBCXX_CXX_ABI=libcxxabi"
#    "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON"
#    "-DLIBCXX_ENABLE_EXCEPTIONS=OFF"
#    "-DLIBCXX_ENABLE_ASSERTIONS=OFF"
#    "-DLIBCXX_ENABLE_RTTI=OFF"
#    "-DLIBCXX_INCLUDE_TESTS=OFF"
#    "-DLIBCXX_INCLUDE_BENCHMARKS=OFF"
#    "-DLIBCXX_ABI_NAMESPACE=__mad1"
#    "-DLIBCXX_USE_COMPILER_RT=ON"
#    # This is an internal option but seems to work fine. madrona links against
#    # this libcxx using -rtlib=compiler-rt so there is no need for libatomic
#    "-DLIBCXX_HAS_ATOMIC_LIB=OFF" 
#    "-DLIBCXXABI_ENABLE_EXCEPTIONS=OFF"
#    "-DLIBCXXABI_ENABLE_SHARED=OFF"
#    "-DLIBCXXABI_ENABLE_ASSERTIONS=OFF"
#    "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
#    "-DLIBCXXABI_USE_COMPILER_RT=ON"
#    "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON"
#    "-DLIBUNWIND_ENABLE_ASSERTIONS=OFF"
#    "-DLIBUNWIND_ENABLE_SHARED=OFF"
#    "-DLIBUNWIND_USE_COMPILER_RT=ON"
#    "-DLLVM_ENABLE_RUNTIMES=libcxx$<SEMICOLON>libcxxabi$<SEMICOLON>libunwind"
#)
#
#
#install(DIRECTORY ${LIBCXX_INSTALL}/include/c++
#    DESTINATION libcxx/include/
#)
#
#install(DIRECTORY ${LIBCXX_INSTALL}/lib/
#    DESTINATION libcxx/lib
#    FILES_MATCHING
#        PATTERN *
#        PATTERN *abi* EXCLUDE
#        PATTERN *experimental* EXCLUDE
#        PATTERN *unwind* EXCLUDE
#        PATTERN *.a EXCLUDE
#)
#
