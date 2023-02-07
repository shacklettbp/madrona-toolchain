set(TOOLCHAIN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/bundled-toolchain")

add_library(madrona_libcxx INTERFACE)
target_compile_options(madrona_libcxx INTERFACE
    -nostdinc++ -fno-exceptions -fno-rtti
)
target_link_options(madrona_libcxx INTERFACE
    -fno-exceptions -fno-rtti
)
target_include_directories(madrona_libcxx SYSTEM INTERFACE
    $<BUILD_INTERFACE:${TOOLCHAIN_ROOT}/libcxx-noexcept/include/c++/v1>
)

find_library(MADRONA_BUNDLED_LIBCXX c++
    PATHS "${TOOLCHAIN_ROOT}/libcxx-noexcept/lib"
    REQUIRED
    NO_DEFAULT_PATH
)

target_link_libraries(madrona_libcxx INTERFACE
    ${MADRONA_BUNDLED_LIBCXX}
)

add_library(madrona_libcxx_except INTERFACE)
target_compile_options(madrona_libcxx_except INTERFACE
    -nostdinc++
)

target_include_directories(madrona_libcxx_except SYSTEM INTERFACE
    $<BUILD_INTERFACE:${TOOLCHAIN_ROOT}/libcxx-except/include/c++/v1>
)

find_library(MADRONA_BUNDLED_LIBCXX_EXCEPT c++
    PATHS "${TOOLCHAIN_ROOT}/libcxx-except/lib"
    REQUIRED
    NO_DEFAULT_PATH
)

target_link_libraries(madrona_libcxx_except INTERFACE
    ${MADRONA_BUNDLED_LIBCXX_EXCEPT}
)

add_library(madrona_libcxx_static INTERFACE)

target_compile_options(madrona_libcxx_static INTERFACE
    -nostdinc++
)

target_include_directories(madrona_libcxx_static SYSTEM INTERFACE
    $<BUILD_INTERFACE:${TOOLCHAIN_ROOT}/libcxx-noexcept/include/c++/v1>
)

target_link_libraries(madrona_libcxx_static INTERFACE
    "${TOOLCHAIN_ROOT}/libcxx-noexcept/lib/libc++.a"
)


add_library(madrona_libcxx_except_static INTERFACE)

target_compile_options(madrona_libcxx_except_static INTERFACE
    -nostdinc++
)

target_include_directories(madrona_libcxx_except_static SYSTEM INTERFACE
    $<BUILD_INTERFACE:${TOOLCHAIN_ROOT}/libcxx-except/include/c++/v1>
)

target_link_libraries(madrona_libcxx_except_static INTERFACE
    "${TOOLCHAIN_ROOT}/libcxx-except/lib/libc++.a"
)

# FIXME proper install support
install(TARGETS madrona_libcxx
    EXPORT madronaLibCXXTarget
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}
)

install(EXPORT madronaLibCXXTarget
    DESTINATION ${CMAKE_INSTALL_PREFIX}
)
