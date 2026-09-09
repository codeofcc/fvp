cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "flutter_video_player")
project(${PROJECT_NAME} LANGUAGES C CXX)
#message(STATUS "FFmpeg configuration 3: CMAKE_C_COMPILER=${CMAKE_C_COMPILER} CMAKE_C_COMPILER_TARGET=${CMAKE_C_COMPILER_TARGET} CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} CMAKE_CXX_COMPILER_TARGET=${CMAKE_CXX_COMPILER_TARGET} CMAKE_SYSTEM_NAME =${CMAKE_SYSTEM_NAME}, CPU=${CMAKE_SYSTEM_PROCESSOR},")
# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_video_player_plugin")

include(${CMAKE_CURRENT_SOURCE_DIR}/../ffi/config.cmake)

add_library(${PLUGIN_NAME} SHARED
  "flutter_video_player_plugin.cc"
  ${PLUGIN_SOURCES}
)





apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_video_player_bundled_libraries
  ""
  PARENT_SCOPE
)
