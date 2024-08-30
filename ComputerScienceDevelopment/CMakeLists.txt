cmake_minimum_required(VERSION 3.26)

project(ALGO)
set(CMAKE_CXX_STANDARD 11)

find_package(OpenCV REQUIRED)
find_package(OpenSSL REQUIRED)
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${OpenSSL_INCLUDE_DIRS})
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)

add_subdirectory(Vigenere)