# Need to explicitly force fPIC on. The LLVM release scripts also do
# this, otherwise we cannot link statically to our libc++.
set(CMAKE_POSITION_INDEPENDENT_CODE ON BOOL "")

set(RUNTIMES_COMMON_ARGS
    "-DCMAKE_EXE_LINKER_FLAGS=-nostdlib++"
    "-DCMAKE_SHARED_LINKER_FLAGS=-nostdlib++"
    "-DCMAKE_MODULE_LINKER_FLAGS=-nostdlib++"
)


set(RUNTIMES_CMAKE_ARGS "${RUNTIMES_COMMON_ARGS}" CACHE STRING "")
set(BUILTINS_CMAKE_ARGS "${RUNTIMES_COMMON_ARGS}" CACHE STRING "")

if (APPLE)
    set(DEFAULT_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/" CACHE STRING "")

    list(RUNTIMES_CMAKE_ARGS APPEND "-DCMAKE_OSX_ARCHITECTURES=arm64|x86_64")
    list(BUILTINS_CMAKE_ARGS APPEND "-DCMAKE_OSX_ARCHITECTURES=arm64|x86_64")
endif()

set(LLVM_ENABLE_PROJECTS "llvm;clang;clang-tools-extra;lld" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "libcxx;libcxxabi;libunwind;compiler-rt" CACHE STRING "")

set(LLVM_ENABLE_ASSERTIONS OFF CACHE BOOL "")
set(LLVM_ENABLE_BACKTRACES OFF CACHE BOOL "")
set(LLVM_ENABLE_Z3_SOLVER OFF CACHE BOOL "")
set(LLVM_ENABLE_UNWIND_TABLES OFF CACHE BOOL "")
set(LLVM_ENABLE_LIBXML2 OFF CACHE BOOL "")

set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")
set(LLVM_INCLUDE_DOCS OFF CACHE BOOL "")
set(LLVM_INCLUDE_BENCHMARKS OFF CACHE BOOL "")
set(LLVM_BUILD_EXAMPLES OFF CACHE BOOL "")
set(LLVM_BUILD_DOCS OFF CACHE BOOL "")
set(LLVM_BUILD_BENCHMARKS OFF CACHE BOOL "")
set(LLVM_INSTALL_CCTOOLS_SYMLINKS ON CACHE BOOL "")

set(CLANG_TOOL_SCAN_BUILD_BUILD OFF CACHE BOOL "")
set(CLANG_TOOL_SCAN_VIEW_BUILD OFF CACHE BOOL "")

set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
set(CLANG_DEFAULT_LINKER lld CACHE STRING "")
set(CLANG_DEFAULT_RTLIB compiler-rt CACHE STRING "")
set(CLANG_DEFAULT_OBJCOPY llvm-objcopy CACHE STRING "")
set(CLANG_DEFAULT_UNWINDLIB libunwind CACHE STRING "")
set(CLANG_PLUGIN_SUPPORT OFF CACHE BOOL "")
set(CLANG_SPAWN_CC1 OFF CACHE BOOL "")

include("${CMAKE_CURRENT_LIST_DIR}/libcxx-common.cmake")

set(LIBCXX_ABI_NAMESPACE __mc1 CACHE STRING "")
set(LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
set(LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
set(LIBCXX_ENABLE_RTTI OFF CACHE BOOL "")

set(COMPILER_RT_USE_LLVM_UNWINDER ON CACHE BOOL "")
set(COMPILER_RT_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
set(COMPILER_RT_CXX_LIBRARY libcxx CACHE STRING "")
set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
set(COMPILER_RT_STATIC_CXX_LIBRARY ON CACHE BOOL "")
set(COMPILER_RT_DEFAULT_TARGET_ONLY ON CACHE BOOL "")
set(COMPILER_RT_INCLUDE_TESTS OFF CACHE BOOL "")

set(SANITIZER_CXX_ABI libc++ CACHE STRING "")
set(SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
set(SANITIZER_TEST_CXX libc++ CACHE STRING "")
set(SANITIZER_TEST_CXX_INTREE ON CACHE BOOL "")
set(SANITIZER_USE_STATIC_CXX_ABI ON CACHE BOOL "")
set(SANITIZER_USE_STATIC_LLVM_UNWINDER ON CACHE BOOL "")
