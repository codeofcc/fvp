#include "player.h"
#include "texture.h"
// #include "video_player_core.h"

#include <cstdint>
#include <memory>
import video_player_core;

struct VideoPlayer : public VideoPlayerCore
{
    VideoPlayer() : texture(std::unique_ptr<flutter_video_player::Texture>(flutter_video_player::Texture::create()))
    {
        setPixelformat(AV_PIX_FMT_RGBA);
        onDisplay = [this](Play *, DisplayEventArgs *args)
        {
            texture->write(args->frame->data[0], args->frame->width, args->frame->height);
        };
    }
    std::unique_ptr<flutter_video_player::Texture> texture;
};

extern "C"
{

    VideoPlayer *video_player_create(void)
    {

        return new VideoPlayer();
    }

    void video_player_destroy(VideoPlayer *handle)
    {
        handle->stop();
        delete handle;
    }

    void video_player_start(VideoPlayer *handle, const char *url)
    {
        handle->start(url);
    }

    void video_player_stop(VideoPlayer *handle)
    {
        handle->stop();
    }

    void video_player_seek(VideoPlayer *handle, double value)
    {
        handle->seek(value);
    }

    // void video_player_set_pixel_format(VideoPlayer *handle, int value)
    // {
    //     handle->setPixelformat(value);
    // }

    void video_player_set_is_paused(VideoPlayer *handle, int value)
    {
        handle->setIsPaused(value);
    }

    void video_player_set_volume(VideoPlayer *handle, int value)
    {
        handle->setVolume(value);
    }

    void video_player_set_speed(VideoPlayer *handle, double value)
    {
        handle->setSpeed(value);
    }

    void video_player_set_is_disable_video(VideoPlayer *handle, int value)
    {
        handle->setIsDisableVideo(value);
    }

    void video_player_set_is_disable_audio(VideoPlayer *handle, int value)
    {
        handle->setIsDisableAudio(value);
    }

    void video_player_set_video_track_index(VideoPlayer *handle, int value)
    {
        handle->setVideoTrackIndex(value);
    }

    void video_player_set_audio_track_index(VideoPlayer *handle, int value)
    {
        handle->setAudioTrackIndex(value);
    }

    int64_t video_player_get_texture_id(VideoPlayerHandle handle)
    {
        return handle->texture->getId();
    }

    void video_player_set_cursor_time_changed_callback(VideoPlayer *handle, CursorTimeChangedCallback callback, void *user_data)
    {
        handle->onCursorTimeChanged = [=](Play *, CursorTimeChangedEventArgs *args)
        {
            callback(handle, args->time, user_data);
        };
    }
}
