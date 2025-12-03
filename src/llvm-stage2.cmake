include("${CMAKE_CURRENT_LIST_DIR}/llvm-common.cmake")

set(LLVM_TARGETS_TO_BUILD AArch64 X86 CACHE STRING "")

set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld" CACHE STRING "")
if (APPLE)
  set(LLVM_ENABLE_RUNTIMES "compiler-rt" CACHE STRING "")
else()
  set(LLVM_ENABLE_RUNTIMES "compiler-rt;libunwind" CACHE STRING "")
endif()

set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_CREATE_XCODE_TOOLCHAIN ON CACHE BOOL "")

set(COMPILER_RT_ENABLE_IOS OFF CACHE BOOL "")
set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
set(COMPILER_RT_DEFAULT_TARGET_ONLY ON CACHE BOOL "")
set(LLVM_BUILD_EXTERNAL_COMPILER_RT ON CACHE BOOL "")

# https://github.com/llvm/llvm-project/issues/63085
# The root cause here seems to be using lld. lld.l64 doesn't correctly handle x86_64h.
if (APPLE)
  set(RUNTIMES_CMAKE_ARGS "-DCMAKE_LINKER_TYPE=SYSTEM" CACHE STRING "")
endif()

if (NOT APPLE)
  set(COMPILER_RT_USE_LLVM_UNWINDER ON CACHE BOOL "")
  set(COMPILER_RT_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
  set(COMPILER_RT_CXX_LIBRARY libcxx CACHE STRING "")
  set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
  set(COMPILER_RT_STATIC_CXX_LIBRARY ON CACHE BOOL "")
  set(SANITIZER_CXX_ABI libc++ CACHE STRING "")
  set(SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
  set(SANITIZER_TEST_CXX libc++ CACHE STRING "")
  set(SANITIZER_TEST_CXX_INTREE ON CACHE BOOL "")
  set(SANITIZER_USE_STATIC_CXX_ABI ON CACHE BOOL "")
  set(SANITIZER_USE_STATIC_LLVM_UNWINDER ON CACHE BOOL "")
endif()

set(LIBCXX_INSTALL_HEADERS OFF CACHE BOOL "")
set(LIBCXX_INSTALL_MODULES OFF CACHE BOOL "")
set(LIBCXX_INSTALL_LIBRARY OFF CACHE BOOL "")
set(LIBCXXABI_INSTALL_HEADERS OFF CACHE BOOL "")
set(LIBCXXABI_INSTALL_MODULES OFF CACHE BOOL "")
set(LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")

if (APPLE OR WIN32)
    set(LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
else()
    # libunwind seems to be linked unconditionally on linux even when no
    # exceptions are used. Need to install the library even though we don't 
    # install libcxx so the compiler isn't broken for cmake checks
    set(LIBUNWIND_INSTALL_LIBRARY ON CACHE BOOL "")
endif()

list(APPEND TOOLCHAIN_TOOLS
    dsymutil
    llvm-ar
    llvm-cxxfilt
    llvm-nm
    llvm-objcopy
    llvm-lipo
    llvm-readelf
    llvm-readobj
    llvm-strip
    llvm-ranlib
    llvm-config
    llvm-dwarfdump
    llvm-profdata
    llvm-objdump
    llvm-cov
)

if (APPLE)
    list(APPEND TOOLCHAIN_TOOLS llvm-libtool-darwin)
endif()

set(LLVM_TOOLCHAIN_TOOLS ${TOOLCHAIN_TOOLS} CACHE STRING "")

set(LLVM_DISTRIBUTION_COMPONENTS
    clang
    lld
    LTO
    clang-apply-replacements
    clang-format
    clang-resource-headers
    clang-include-fixer
    clang-refactor
    clang-scan-deps
    clang-tidy
    clangd
    find-all-symbols
    Remarks
    builtins
    runtimes
    compiler-rt
    ${LLVM_TOOLCHAIN_TOOLS}

    CACHE STRING ""
)
