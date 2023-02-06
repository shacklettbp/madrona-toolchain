include("${CMAKE_CURRENT_LIST_DIR}/llvm-common.cmake")

set(LLVM_TARGETS_TO_BUILD "AArch64;X86" CACHE STRING "")

#set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_CREATE_XCODE_TOOLCHAIN ON CACHE BOOL "")

set(LLVM_BUILD_LLVM_DYLIB ON CACHE BOOL "")
set(LLVM_DYLIB_COMPONENTS "Core;MC;MCDisassembler;Analysis;Support;Target;BitReader;BitWriter;Vectorize;ipo;InstCombine;TransformUtils;ScalarOpts;Object" CACHE STRING "")

set(LIBCXX_INSTALL_HEADERS OFF CACHE BOOL "")
set(LIBCXX_INSTALL_LIBRARY OFF CACHE BOOL "")
set(LIBCXXABI_INSTALL_HEADERS OFF CACHE BOOL "")
set(LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")

if (APPLE)
    # macOS universal build fails with LTO due to mixed LLVM IR and MachO
    # .o files in libLLVMSupport.a. This option disables those assembly files
    # with no other impact currently (LLVM 15) than slightly reduced x86 perf.
    set(LLVM_DISABLE_ASSEMBLY_FILES ON CACHE BOOL "")
endif()

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
    llvm-profdata
    llvm-objdump
    llvm-cov

    CACHE STRING ""
)

set(LLVM_DISTRIBUTION_COMPONENTS
    clang
    libclang
    libclang-headers
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
    LLVM
    ${LLVM_TOOLCHAIN_TOOLS}

    CACHE STRING ""
)
