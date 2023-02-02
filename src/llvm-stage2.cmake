include("${CMAKE_CURRENT_LIST_DIR}/llvm-common.cmake")

set(LLVM_TARGETS_TO_BUILD "AArch64;X86" CACHE STRING "")
set(LLVM_STATIC_LINK_CXX_STDLIB ON CACHE BOOL "") # Binary size increase?

set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_TOOLCHAIN_TOOLS
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

    CACHE STRING ""
)

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
    ${LLVM_TOOLCHAIN_TOOLS}

    CACHE STRING ""
)
