include(FetchContent)

# ── SDL2 极简音频配置 ──
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(SDL2_DISABLE_SDL2MAIN ON CACHE BOOL "" FORCE)
set(SDL2_DISABLE_UNINSTALL ON CACHE BOOL "" FORCE)
# 音频核心（必须）
set(SDL_AUDIO ON CACHE BOOL "" FORCE)

# 音频依赖（必须）
set(SDL_THREADS ON CACHE BOOL "" FORCE) # ⚠️ SDL 强制要求，不能关闭

# 关闭其他不需要的模块
foreach(_sdl_mod
  EVENTS
  FILE
  MISC
  TIMERS
  ATOMIC
  VIDEO RENDER JOYSTICK HAPTIC SENSOR TOUCH POWER
  DIRECTX OPENGLES VULKAN LOADSO CPUINFO
  VIRTUAL_JOYSTICK RENDER_D3D LIBUDEV HIDAPI_JOYSTICK
  FILESYSTEM LOCALE
  # 各种音频后端（仅保留 WASAPI）
  ALSA PULSEAUDIO JACK PIPEWIRE ESD ARTS NAS SNDIO FUSIONSOUND
  # 各种平台
  X11 WAYLAND DIRECTFB KMSDRM COCOA
  DISKAUDIO
  DUMMYAUDIO
  DUMMYVIDEO
  HIDAPI
  OPENGL
  OFFSCREEN
  XINPUT
  ALTIVEC
  CCACHE
)
  set(SDL_${_sdl_mod} OFF CACHE BOOL "" FORCE)
endforeach()

FetchContent_Declare(
  SDL2
  GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
  GIT_TAG release-2.30.12
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(SDL2)

FetchContent_Declare(
  libgo
  GIT_REPOSITORY https://github.com/codeofcc/libgo
  GIT_TAG master # 或 main，或你 fork 的分支名
  GIT_SHALLOW TRUE # 可选，加快下载
)

# 在 MakeAvailable 之前设置 libgo 的选项（覆盖默认值）
set(LIBGO_ENABLE_DEBUGGER OFF CACHE BOOL "" FORCE)
set(LIBGO_DISABLE_HOOK OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(libgo)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../ffi/include")
file(GLOB_RECURSE SRC_FILES
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/../ffi/src/*.cpp"
)

list(APPEND LIB_FILES
  SDL2::SDL2
  libgo::libgo
)

# ── 平台相关配置 ──
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  # list(APPEND INCLUDE_DIRS
  #   ${CMAKE_CURRENT_SOURCE_DIR}/../ffi/sdk/ffmpeg/include
  # )
  # file(GLOB_RECURSE FFMPEG_LIBRARIES
  #   ${CMAKE_CURRENT_SOURCE_DIR}/../ffi/sdk/ffmpeg/lib/*.lib
  # )
  # list(APPEND LIB_FILES
  #   ${FFMPEG_LIBRARIES}
  # )
  # file(GLOB_RECURSE  BUNDLED_FILES
  #   ${CMAKE_CURRENT_SOURCE_DIR}/../ffi/sdk/ffmpeg/bin/*.dll
  # )
  # set(VCPKG_MANIFEST_MODE ON)
  set(VCPKG_DIR "${CMAKE_BINARY_DIR}/vcpkg")
  set(FFMPEG_VERSION_TAG "2026.06.24") # 👈 指定目标版本 8.1.2 //查看方式：在vcpkg的git查看ffmpeg包的版本对应的tag
  find_package(Git REQUIRED)

  if(NOT EXISTS "${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake")
    execute_process(COMMAND ${GIT_EXECUTABLE} clone -b ${FFMPEG_VERSION_TAG} --depth=1 https://github.com/microsoft/vcpkg.git "${VCPKG_DIR}" COMMAND_ERROR_IS_FATAL ANY)
    execute_process(COMMAND "${VCPKG_DIR}/bootstrap-vcpkg.bat" -disableMetrics WORKING_DIRECTORY "${VCPKG_DIR}" COMMAND_ERROR_IS_FATAL ANY)
  endif()
  # 3. 注入 toolchain 并安装（保持 HEAD 最新状态）
  set(CMAKE_TOOLCHAIN_FILE "${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE FILEPATH "")
  execute_process(
    COMMAND "${VCPKG_DIR}/vcpkg.exe" install "ffmpeg[core,avcodec,avformat,swresample,swscale]:x64-windows"
    WORKING_DIRECTORY "${VCPKG_DIR}"
    COMMAND_ECHO STDOUT
    COMMAND_ERROR_IS_FATAL ANY
  )
  list(APPEND CMAKE_MODULE_PATH "${VCPKG_DIR}/installed/x64-windows/share/ffmpeg")
  find_package(FFMPEG MODULE REQUIRED)
  list(APPEND INCLUDE_DIRS ${FFMPEG_INCLUDE_DIRS})

  #安装dll，区分debug和release模式
  set(_VCPKG_BASE "${VCPKG_DIR}/installed/x64-windows")
  file(GLOB _RELEASE_DLLS "${_VCPKG_BASE}/bin/*.dll")
  file(GLOB _DEBUG_DLLS "${_VCPKG_BASE}/debug/bin/*.dll")
  string(REPLACE ";" "$<SEMICOLON>" _REL_STR "${_RELEASE_DLLS}")
  string(REPLACE ";" "$<SEMICOLON>" _DBG_STR "${_DEBUG_DLLS}")
  set(BUNDLED_FILES
    "$<$<NOT:$<CONFIG:Debug>>:${_REL_STR}>"
    "$<$<CONFIG:Debug>:${_DBG_STR}>"
  )

  message(STATUS "BUNDLED_FILES:${BUNDLED_FILES}")


  # message(STATUS "FFMPEG_LIBRARIES: ${FFMPEG_LIBRARIES}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  # Linux 配置占位
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  message(STATUS "macOS build")
endif()

list(APPEND PLUGIN_SOURCES ${SRC_FILES})
