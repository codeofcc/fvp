set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


include(FetchContent)

find_package(Git REQUIRED)

# 通用 git clone 函数
# 用法: git_clone_if_needed(<url> <tag> <dest_dir>)
function(git_clone_if_needed _url _tag _dest)
  if(EXISTS "${_dest}/.git")
    message(STATUS "[Git] ${_dest} already exists, skipping clone.")
    return()
  endif()

  message(STATUS "[Git] Cloning ${_url} (tag: ${_tag}) -> ${_dest}")
  file(MAKE_DIRECTORY "${_dest}")

  execute_process(
    COMMAND ${GIT_EXECUTABLE} clone --depth 1 -b "${_tag}" "${_url}" "${_dest}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _output
    ERROR_VARIABLE _error
  )

  if(NOT _result EQUAL 0)
    # clone 失败时清理残留空目录，避免下次误判为"已存在"
    file(REMOVE_RECURSE "${_dest}")
    message(FATAL_ERROR "[Git] Clone failed (${_result}): ${_error}")
  endif()

  message(STATUS "[Git] Clone succeeded: ${_dest}")
endfunction()


include(FetchContent)



set(FFI_PACKAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/_deps")


git_clone_if_needed(
  "https://github.com/codeofcc/video_player_core"
  "main"
  "${FFI_PACKAGE_DIR}/video_player_core"
)


FetchContent_Declare(
  video_player_core
  SOURCE_DIR "${FFI_PACKAGE_DIR}/video_player_core"
)
FetchContent_MakeAvailable(video_player_core)

file(GLOB_RECURSE FFI_SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.cpp"
)


add_library(${PLUGIN_NAME}_FFI STATIC
  ${FFI_SOURCES}
)

target_include_directories(${PLUGIN_NAME}_FFI PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/include"
)
# add_dependencies(${PLUGIN_NAME}_FFI video_player_core)
set(CMAKE_CXX_SCAN_FOR_MODULES ON) 
# set_target_properties(video_player_core PROPERTIES CXX_SCAN_FOR_MODULES TRUE)
set_target_properties(${PLUGIN_NAME}_FFI PROPERTIES CXX_SCAN_FOR_MODULES TRUE)
target_link_libraries(${PLUGIN_NAME}_FFI PRIVATE video_player_core::video_player_core)

# # Enable C++20 modules for the FFI library
# target_compile_features(${PLUGIN_NAME}_FFI PRIVATE cxx_std_20)

# # Add module interface path for C++20 module support
# # This allows player.cpp to import video_player_core module
# target_include_directories(${PLUGIN_NAME}_FFI PRIVATE
#   "${FFI_PACKAGE_DIR}/video_player_core/include"
# )


# Pass the compiled module file (.pcm) to the compiler
# The module is compiled as part of video_player_core library

# target_compile_options(${PLUGIN_NAME}_FFI PRIVATE
#   "-fmodule-file=video_player_core=${CMAKE_BINARY_DIR}/_deps/video_player_core-build/CMakeFiles/video_player_core.dir/video_player_core.pcm"
# )



target_compile_definitions(${PLUGIN_NAME}_FFI PRIVATE PLAYER_EXPORTS)

target_link_libraries(${PLUGIN_NAME} PUBLIC ${PLUGIN_NAME}_FFI )
