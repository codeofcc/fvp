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
  "https://github.com/codeofcc/vpc"
  "main"
  "${FFI_PACKAGE_DIR}/vpc"
)


FetchContent_Declare(
  vpc
  SOURCE_DIR "${FFI_PACKAGE_DIR}/vpc"
)
FetchContent_MakeAvailable(vpc)

file(GLOB_RECURSE PLUGIN_SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.cpp"
)

# # set(CMAKE_POSITION_INDEPENDENT_CODE ON)
# add_library(${PLUGIN_NAME}_FFI STATIC
#   ${FFI_SOURCES}
# )

# set_target_properties(${PLUGIN_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)










function(my_finalizer)
  message(STATUS "[Finalizer] 正在处理插件: ${PLUGIN_NAME}" "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/include")
  target_include_directories(${PLUGIN_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/include"
  )


  # add_dependencies(${PLUGIN_NAME}_FFI video_player_core)
  set(CMAKE_CXX_SCAN_FOR_MODULES ON)
  # set_target_properties(video_player_core PROPERTIES CXX_SCAN_FOR_MODULES TRUE)
  set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_SCAN_FOR_MODULES TRUE)
  target_link_libraries(${PLUGIN_NAME} PRIVATE vpc::vpc)
  target_compile_definitions(${PLUGIN_NAME} PRIVATE PLAYER_EXPORTS)

  if(FLUTTER_TARGET_PLATFORM MATCHES "elinux")
    target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLATFORM_ELINUX)
  elseif(FLUTTER_TARGET_PLATFORM MATCHES "linux")
    target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLATFORM_LINUX)
  endif()


  target_compile_options(${PLUGIN_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W0> # Windows: 关闭所有警告
    $<$<CXX_COMPILER_ID:GNU>:-w> # Linux/GCC: 关闭所有警告
    $<$<CXX_COMPILER_ID:Clang>:-w> # Mac/Clang: 关闭所有警告
  )


  # if(MSVC)
  #   target_compile_options(${PLUGIN_NAME} PRIVATE /UFLUTTER_PLUGIN_IMPL)
  # else()
  #   # target_compile_options(${PLUGIN_NAME} PRIVATE -UFLUTTER_PLUGIN_IMPL)
  # endif()



  # 在这里执行你需要的收尾操作...
endfunction()

# 【关键】使用 EVAL CODE 包裹 DEFER，并使用 [[${var}]] 强制立即求值
cmake_language(EVAL CODE
  "cmake_language(DEFER CALL my_finalizer [[${PLUGIN_NAME}]])"
)
