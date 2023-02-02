include("${CMAKE_CURRENT_LIST_DIR}/llvm-common.cmake")

set(LLVM_INCLUDE_TESTS OFF CACHE BOOL "")
set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "")
set(LLVM_ENABLE_LTO OFF CACHE STRING "")

set(CLANG_BOOTSTRAP_PASSTHROUGH
    CMAKE_INSTALL_PREFIX
    CMAKE_BUILD_TYPE
    LLVM_DEFAULT_TARGET_TRIPLE

    CACHE STRING ""
)

set(CLANG_ENABLE_BOOTSTRAP ON CACHE BOOL "")
set(CLANG_BOOTSTRAP_CMAKE_ARGS
    -C ${CMAKE_CURRENT_LIST_DIR}/llvm-stage2.cmake
    CACHE STRING ""
)

set(BOOTSTRAP_LLVM_ENABLE_LTO THIN CACHE STRING "")
set(BOOTSTRAP_LLVM_ENABLE_LLD ON CACHE BOOL "")
set(BOOTSTRAP_LLVM_ENABLE_LIBCXX ON CACHE BOOL "")

set(CLANG_BOOTSTRAP_TARGETS
    check-all
    check-clang
    check-lld
    check-llvm
    llvm-config
    clang-test-depends
    lld-test-depends
    llvm-test-depends
    test-suite
    test-depends
    distribution
    install-distribution
    install-distribution-stripped
    install-distribution-toolchain
    clang

    CACHE STRING ""
)

set(CLANG_BOOTSTRAP_EXTRA_DEPS
    builtins
    runtimes

    CACHE STRING ""
)
