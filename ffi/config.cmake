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

set(SDL_IME OFF CACHE BOOL "" FORCE) # 禁用输入法框架 (IBus/Fcitx)
set(SDL_IBUS OFF CACHE BOOL "" FORCE) # 显式禁用 IBus
set(SDL_FCITX OFF CACHE BOOL "" FORCE) # 显式禁用 Fcitx
set(SDL_HIDAPI OFF CACHE BOOL "" FORCE)

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

list(APPEND LIBRARIES
  SDL2::SDL2
  libgo::libgo
)

# ── 平台相关配置 ──
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")

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
    COMMAND "${VCPKG_DIR}/vcpkg.exe" install "ffmpeg[avcodec,avformat,swresample,swscale]:x64-windows-static-md"
    WORKING_DIRECTORY "${VCPKG_DIR}"
    COMMAND_ECHO STDOUT
    COMMAND_ERROR_IS_FATAL ANY
  )

  list(APPEND CMAKE_MODULE_PATH "${VCPKG_DIR}/installed/x64-windows-static-md/share/ffmpeg")

  find_package(FFMPEG MODULE REQUIRED)
  list(APPEND INCLUDE_DIRS ${FFMPEG_INCLUDE_DIRS})

elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

  # set(FFMPEG_INSTALL_DIR "${CMAKE_BINARY_DIR}/_deps/ffmpeg-build/install")

  # execute_process(COMMAND bash -c "FFMPEG_SOURCE_DIR=${CMAKE_BINARY_DIR}/_deps/ffmpeg-src FFMPEG_BUILD_DIR=${CMAKE_BINARY_DIR}/_deps/ffmpeg-build  PREFIX=${FFMPEG_INSTALL_DIR}  CC=${CMAKE_C_COMPILER} ${CMAKE_CURRENT_SOURCE_DIR}/../ffi/script/build_ffmpeg.sh" RESULT_VARIABLE result)
  # if(NOT ${result} EQUAL 0)
  #   message(FATAL_ERROR "Command failed: ${result} ${TARGET_SYSROOT} ${CMAKE_C_COMPILER}")
  # endif()

  # file(GLOB LIBRARIES "${FFMPEG_INSTALL_DIR}/lib/*.so*")

  # list(APPEND BUNDLED_FILES "${LIB_FILES}")
  # list(APPEND INCLUDE_DIRS "${FFMPEG_INSTALL_DIR}/include")

  include(ProcessorCount)
  ProcessorCount(NPROC)
  if(NPROC EQUAL 0)
    set(NPROC 1)
  endif()


  # 路径变量
  set(FFMPEG_INSTALL_DIR "${CMAKE_BINARY_DIR}/_deps/ffmpeg-build/install")
  set(FFMPEG_SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/ffmpeg-src")

  if(NOT EXISTS "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a")
    # 下载并构建
    include(ExternalProject)
    ExternalProject_Add(ffmpeg
      BUILD_ALWAYS OFF
      # UPDATE_COMMAND ""
      # UPDATE_DISCONNECTED ON
      SOURCE_DIR "${FFMPEG_SOURCE_DIR}"
      BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/ffmpeg-build"
      PREFIX "${FFMPEG_INSTALL_DIR}"
      GIT_REPOSITORY "https://git.ffmpeg.org/ffmpeg.git"
      GIT_TAG "n8.1.2"
      GIT_SHALLOW TRUE
      CONFIGURE_COMMAND
      #${CMAKE_COMMAND} -E echo "FFmpeg configure skipped (using pre-built libraries)"
      ${CMAKE_COMMAND} -E env CC=${CMAKE_C_COMPILER}
      C_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}
      # ASFLAGS=-fPIC
      ${FFMPEG_SOURCE_DIR}/configure
      --prefix=${FFMPEG_INSTALL_DIR}
      --cc=${CMAKE_C_COMPILER}
      --arch=x86_64
      --cpu=x86-64
      --target-os=linux
      # === 核心策略 ===
      --disable-everything
      --disable-autodetect # ← 防止隐式依赖
      --disable-shared --enable-static
      --disable-programs # 不构建 ffmpeg/ffprobe/ffplay
      --disable-doc
      # === 移除无用子系统 ===
      --disable-encoders --disable-muxers --disable-bsfs
      --disable-filters
      --disable-indevs --disable-outdevs
      # === 移除外部库依赖 ===
      --disable-iconv --disable-zlib --disable-bzlib --disable-lzma
      --disable-sdl2 --disable-xlib #--disable-xcb
      --disable-alsa --disable-sndio #--disable-pulseaudio --disable-jack
      # === 移除平台特定硬件加速 ===
      --disable-vaapi --disable-vdpau
      --disable-cuda --disable-cuvid --disable-nvenc --disable-nvdec
      --disable-amf --disable-d3d11va --disable-dxva2
      --disable-videotoolbox --disable-audiotoolbox
      --disable-mediacodec
      --disable-v4l2-m2m #--disable-v4l2
      #禁用
      --disable-asm
      # === 保留的功能 ===
      --enable-network --enable-protocols
      --enable-demuxers --enable-parsers
      --enable-decoders --enable-hwaccels
      --enable-swscale --enable-swresample
      #静态库
      --disable-shared --enable-static
      # --pkg-config=pkg-config --pkg-config-flags=--static
      --enable-pic
      # === 编译选项 ===
      "--extra-cflags=-fPIC $<$<CONFIG:Debug>:-g -O0 -DDEBUG>$<$<CONFIG:RelWithDebInfo>:-g -O2 -DNDEBUG>$<$<CONFIG:MinSizeRel>:-Os -DNDEBUG>$<$<NOT:$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>,$<CONFIG:MinSizeRel>>>:-O2 -DNDEBUG>"
      $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:--enable-debug>$<$<NOT:$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>>:--disable-debug>


      BUILD_COMMAND make -j${NPROC}

      INSTALL_COMMAND make install

      BUILD_BYPRODUCTS
      "${FFMPEG_INSTALL_DIR}/lib/libavcodec.a"
      "${FFMPEG_INSTALL_DIR}/lib/libavformat.a"
      "${FFMPEG_INSTALL_DIR}/lib/libavutil.a"
      "${FFMPEG_INSTALL_DIR}/lib/libswscale.a"
      "${FFMPEG_INSTALL_DIR}/lib/libswresample.a"
    )
  endif()
  list(APPEND INCLUDE_DIRS
    ${FFMPEG_INSTALL_DIR}/include
  )

  list(APPEND LIBRARIES
    ${FFMPEG_INSTALL_DIR}/lib/libavformat.a
    ${FFMPEG_INSTALL_DIR}/lib/libavcodec.a
    ${FFMPEG_INSTALL_DIR}/lib/libswscale.a
    ${FFMPEG_INSTALL_DIR}/lib/libswresample.a
    ${FFMPEG_INSTALL_DIR}/lib/libavutil.a
  )

  # Linux 配置占位
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  message(STATUS "macOS build")
endif()

list(APPEND PLUGIN_SOURCES ${SRC_FILES})
