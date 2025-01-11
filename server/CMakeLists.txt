cmake_minimum_required(VERSION 3.16)

project(nw3d_server)

set(CMAKE_C_STANDARD 17)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(nw3d_server main.c config.c network.c simulation.c vector.c seconds.c)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_compile_options(nw3d_server PRIVATE -march=x86-64-v3 -Wall -Wextra -Wpedantic)
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(nw3d_server PRIVATE /arch:AVX2 /W4)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    #target_link_libraries(nw3d_server PRIVATE m)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(nw3d_server PRIVATE ws2_32)
endif()
