cmake_minimum_required(VERSION 3.15)

project(Data-Struct)
set(CMAKE_CXX_STANDARD 23)

set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)

# Debug
set(DCMAKE_EXPORT_COMPILE_COMMANDS ON)

add_subdirectory(Algo)
add_subdirectory(DS)
