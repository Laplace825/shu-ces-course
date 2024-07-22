file(GLOB_RECURSE ALGO_SRCS *.cpp)

foreach(ALGO_SRC ${ALGO_SRCS})
    get_filename_component(ALGO_SRC_DIR ${ALGO_SRC} DIRECTORY)
    string(REGEX REPLACE ".*/(.*)" "\\1" CURRENT_FOLDER_ABSOLUTE ${ALGO_SRC_DIR})
    add_executable(${CURRENT_FOLDER_ABSOLUTE} ${ALGO_SRC})
endforeach()