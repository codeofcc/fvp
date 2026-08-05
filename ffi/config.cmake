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

# ── 下载 libgo ──
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


target_link_libraries(${PLUGIN_NAME} PRIVATE video_player_core::video_player_core)
