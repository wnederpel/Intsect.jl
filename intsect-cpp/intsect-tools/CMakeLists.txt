# Developer tools executable and shared tooling library.

add_library(intsect-tooling STATIC
  src/perft_diff.cpp)

target_include_directories(intsect-tooling
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include)

target_link_libraries(intsect-tooling
  PUBLIC
    intsect-engine
  PRIVATE
    intsect_options)

add_executable(intsect-tools
  src/main.cpp)

target_link_libraries(intsect-tools PRIVATE
  intsect-tooling
  intsect-engine
  intsect_options)

intsect_copy_runtime_deps(intsect-tools)
