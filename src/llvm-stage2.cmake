include("${CMAKE_CURRENT_LIST_DIR}/llvm-common.cmake")

set(LLVM_TARGETS_TO_BUILD AArch64 X86 CACHE STRING "")

set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_CREATE_XCODE_TOOLCHAIN ON CACHE BOOL "")

set(COMPILER_RT_ENABLE_IOS OFF CACHE BOOL "")
set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
set(LLVM_BUILD_EXTERNAL_COMPILER_RT ON CACHE BOOL "")

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
    builtins
    runtimes
    Remarks
    compiler-rt
    ${LLVM_TOOLCHAIN_TOOLS}

    CACHE STRING ""
)
