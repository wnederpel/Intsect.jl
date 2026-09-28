# The engine library: build all implementation files in src/.
file(GLOB ENGINE_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
)

add_library(intsect-engine STATIC ${ENGINE_SOURCES})

target_include_directories(intsect-engine PUBLIC include)

target_link_libraries(intsect-engine PUBLIC intsect_options)
