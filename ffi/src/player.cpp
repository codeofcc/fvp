#include "player.h"
// #include "video_player_core.h"

#include <cstdint>
import video_player_core; 

struct VideoPlayer : public VideoPlayerCore {};

extern "C" {

VideoPlayer* video_player_create(void) {
    return new VideoPlayer();
}

void video_player_destroy(VideoPlayer* handle) {
    handle->stop();
    delete handle;
}

void video_player_start(VideoPlayer* handle, const char* url) {
    handle->start(url);
}

void video_player_stop(VideoPlayer* handle) {
    handle->stop();
}

void video_player_seek(VideoPlayer* handle, double value) {
    handle->seek(value);
}

void video_player_set_pixel_format(VideoPlayer* handle, int value) {
    handle->setPixelformat(value);
}

void video_player_set_is_paused(VideoPlayer* handle, int value) {
    handle->setIsPaused(value);
}

void video_player_set_volume(VideoPlayer* handle, int value) {
    handle->setVolume(value);
}

void video_player_set_speed(VideoPlayer* handle, double value) {
    handle->setSpeed(value);
}

void video_player_set_is_disable_video(VideoPlayer* handle, int value) {
    handle->setIsDisableVideo(value);
}

void video_player_set_is_disable_audio(VideoPlayer* handle, int value) {
    handle->setIsDisableAudio(value);
}

void video_player_set_video_track_index(VideoPlayer* handle, int value) {
    handle->setVideoTrackIndex(value);
}

void video_player_set_audio_track_index(VideoPlayer* handle, int value) {
    handle->setAudioTrackIndex(value);
}

void video_player_set_display_callback(VideoPlayer* handle, DisplayCallback callback, void* user_data) {
    handle->onDisplay = [=](Play*, DisplayEventArgs* args) {
        callback(handle, 0, args->frame->width, args->frame->height,
                 args->frame->data[0], 0, user_data);
    };
}

void video_player_set_cursor_time_changed_callback(VideoPlayer* handle, CursorTimeChangedCallback callback, void* user_data) {
    handle->onCursorTimeChanged = [=](Play*, CursorTimeChangedEventArgs* args) {
        callback(handle, args->time, user_data);
    };
}

}
