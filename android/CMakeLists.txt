cmake_minimum_required(VERSION 3.10)

# message(STATUS "CMAKE_SYSTEM_VERSION = ${CMAKE_SYSTEM_VERSION}")
# message(STATUS "CMAKE_ANDROID_API = ${CMAKE_ANDROID_API}")
# message(STATUS "ANDROID_PLATFORM = ${ANDROID_PLATFORM}")
# message(STATUS "ANDROID_NATIVE_API_LEVEL = ${ANDROID_NATIVE_API_LEVEL}")


set(PLUGIN_NAME "fvp_plugin")



# Include the FFI config
include(${CMAKE_CURRENT_SOURCE_DIR}/../ffi/config.cmake)

# Add the native library
add_library(${PLUGIN_NAME} SHARED
    ${PLUGIN_SOURCES}
)


target_compile_options(${PLUGIN_NAME} PRIVATE -pthread)
find_package(Threads REQUIRED)
# find_library( # Sets the name of the path variable.
#     log-lib

#     # Specifies the name of the NDK library that
#     # you want CMake to locate.
#     log)

target_link_libraries(${PLUGIN_NAME} PRIVATE
    Threads::Threads
    android
)


target_compile_options(${PLUGIN_NAME} PRIVATE -Wno-error)

set_target_properties(${PLUGIN_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)



# # Link with Flutter
# target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
