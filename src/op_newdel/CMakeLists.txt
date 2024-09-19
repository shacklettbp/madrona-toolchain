cmake_minimum_required(VERSION 3.18 FATAL_ERROR)
cmake_policy(VERSION 3.18)
project(madrona-toolchain-standalone-op-newdel LANGUAGES C CXX)

set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED 11)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED 20)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

add_library(madrona_toolchain_standalone_op_newdel STATIC
    op_newdel.cpp
)
target_compile_options(madrona_toolchain_standalone_op_newdel PRIVATE
    -Wall -Wextra -pedantic
    -nostdinc++ -fno-exceptions -fno-rtti 
    -fvisibility-global-new-delete-hidden
)
set_property(TARGET madrona_toolchain_standalone_op_newdel PROPERTY
    POSITION_INDEPENDENT_CODE TRUE)

install(TARGETS madrona_toolchain_standalone_op_newdel)
