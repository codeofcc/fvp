#pragma once
#include <stdint.h>

// Cross-platform export macro
#ifdef _WIN32
    #ifdef PLAYER_EXPORTS
        #define PLAYER_EXPORT __declspec(dllexport)
    #else
        #define PLAYER_EXPORT __declspec(dllimport)
    #endif
#else
    #define PLAYER_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle to Play instance
typedef struct VideoPlayer* VideoPlayerHandle;

// Callback types
typedef void (*DisplayCallback)(VideoPlayerHandle handle, int64_t timestamp_us, int width, int height, const uint8_t* data, int data_size, void* user_data);
typedef void (*CursorTimeChangedCallback)(VideoPlayerHandle handle, double time, void* user_data);

// Create/destroy
PLAYER_EXPORT VideoPlayerHandle video_player_create(void);
PLAYER_EXPORT void video_player_destroy(VideoPlayerHandle handle);

// Setters
PLAYER_EXPORT void video_player_start(VideoPlayerHandle handle, const char* url);
PLAYER_EXPORT void video_player_stop(VideoPlayerHandle handle);
PLAYER_EXPORT void video_player_seek(VideoPlayerHandle handle, double value);
PLAYER_EXPORT void video_player_set_pixel_format(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_is_paused(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_volume(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_speed(VideoPlayerHandle handle, double value);
PLAYER_EXPORT void video_player_set_is_disable_video(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_is_disable_audio(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_video_track_index(VideoPlayerHandle handle, int value);
PLAYER_EXPORT void video_player_set_audio_track_index(VideoPlayerHandle handle, int value);

// Callbacks
PLAYER_EXPORT void video_player_set_display_callback(VideoPlayerHandle handle, DisplayCallback callback, void* user_data);
PLAYER_EXPORT void video_player_set_cursor_time_changed_callback(VideoPlayerHandle handle, CursorTimeChangedCallback callback, void* user_data);

#ifdef __cplusplus
}
#endif
