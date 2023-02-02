cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
set(NAME madrona-toolchain-compile)

if (MADRONA_MACOS)
    set(CMAKE_OSX_ARCHITECTURES arm64;x86_64)
endif()

project(${NAME})

include(FetchContent)
include(ExternalProject)

find_package(Python 3.6 COMPONENTS Interpreter)

get_filename_component(PARENT_DIR ${CMAKE_SOURCE_DIR} DIRECTORY)
include(${PARENT_DIR}/cmake/sys-detect.cmake)

include(versions.cmake)

list(APPEND LLVM_COMMON_ARGS
    "-DCMAKE_BUILD_TYPE=Release"
)

set(LLVM_C_FLAGS "")
set(LLVM_CXX_FLAGS "")

if (MADRONA_X64)
    set(LLVM_C_FLAGS "${LLVM_C_FLAGS} -march=x86-64-v3")
    set(LLVM_CXX_FLAGS "${LLVM_CXX_FLAGS} -march=x86-64-v3")
endif()

if (MADRONA_MACOS)
    list(APPEND LLVM_COMMON_ARGS
        "-DCMAKE_OSX_ARCHITECTURES=arm64$<SEMICOLON>x86_64"
    )
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

set(LLVM_STAGE2_CXX_FLAGS "${LLVM_CXX_FLAGS} -fno-exceptions -fno-rtti")
set(LLVM_STAGE2_LINKER_FLAGS "${LLVM_CXX_FLAGS} -fno-exceptions -fno-rtti")

list(APPEND LLVM_TOOLCHAIN_ARGS
    "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_C_FLAGS=${LLVM_C_FLAGS}"
    "-DCMAKE_CXX_FLAGS=${LLVM_CXX_FLAGS}"
    "-DCMAKE_INSTALL_PREFIX=${LLVM_TOOLCHAIN_INSTALL}"
    "-DBOOTSTRAP_CMAKE_C_FLAGS=${LLVM_C_FLAGS}"
    "-DBOOTSTRAP_CMAKE_CXX_FLAGS=${LLVM_STAGE2_CXX_FLAGS}"
    "-DBOOTSTRAP_CMAKE_EXE_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_SHARED_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_MODULE_LINKER_FLAGS=${LLVM_STAGE2_LINKER_FLAGS}"
    "-DBOOTSTRAP_CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}"
    "-C ${CMAKE_CURRENT_LIST_DIR}/llvm-stage1.cmake"
)

if (MADRONA_X64 AND MADRONA_LINUX)
    LIST(APPEND LLVM_TOOLCHAIN_ARGS 
        "-DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-pc-linux-gnu"
    )
endif()

ExternalProject_Add(llvm_toolchain
    SOURCE_DIR "${llvm_project_SOURCE_DIR}"
    PREFIX "${LLVM_TOOLCHAIN_PREFIX}"
    BINARY_DIR "${LLVM_TOOLCHAIN_BUILD}"
    INSTALL_DIR "${LLVM_TOOLCHAIN_INSTALL}"
    CMAKE_GENERATOR Ninja
    CMAKE_ARGS
        ${LLVM_COMMON_ARGS}
        ${LLVM_TOOLCHAIN_ARGS}
    SOURCE_SUBDIR llvm
    BUILD_COMMAND ninja -C "${LLVM_TOOLCHAIN_BUILD}" stage2-distribution
    INSTALL_COMMAND ninja -C "${LLVM_TOOLCHAIN_BUILD}" stage2-install-distribution-stripped
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
