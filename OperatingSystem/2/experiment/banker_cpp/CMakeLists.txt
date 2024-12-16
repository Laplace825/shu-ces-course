cmake_minimum_required(VERSION 3.30)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_C_COMPILER clang)

set(CMAKE_GENERATOR "Ninja")
set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/bin")

project(banker LANGUAGES CXX)

add_executable(${PROJECT_NAME})

file(GLOB_RECURSE SOURCES "src/*.cc")

add_library("${PROJECT_NAME}lib" STATIC ${SOURCES})

target_sources(${PROJECT_NAME}
    PUBLIC
      main.cc
)

target_include_directories("${PROJECT_NAME}lib"
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_include_directories(${PROJECT_NAME}
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(${PROJECT_NAME}
  PUBLIC
    "${PROJECT_NAME}lib"
)


target_compile_options(${PROJECT_NAME}
  PUBLIC
    -Wall
    -Werror
    -Wextra
    -Wpedantic
)
