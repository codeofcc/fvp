#include "player.h"
#include "texture.h"
// #include "video_player_core.h"

#include <cstdint>
#include <memory>
extern "C"
{
#include "acplay.h"
}

import video_player_core;

struct VideoPlayer //: public VideoPlayerCore
{
    VideoPlayer() : texture(std::unique_ptr<flutter_video_player::Texture>(flutter_video_player::Texture::create()))
    {
        _play = ac_play_create();
        ac_play_setUserData(_play, this);
        ac_play_setStartedCallback(_play, [](ACPlay play, ACPixelFormat *format, int width, int height, double duration)
                                   { *format = (ACPixelFormat)::AVPixelFormat::AV_PIX_FMT_RGBA; });

        ac_play_setDisplayCallback(_play, [](ACPlay play, unsigned char *data[8], int linesize[8], int width, int height, ACPixelFormat format, int *isHandled)
                                   {
                                       auto _this = (VideoPlayer *)ac_play_getUserData(play);
                                        auto frame = av_frame_clone((const AVFrame *)data);
            _this->texture->write(frame->data[0], frame->width, frame->height, [=]()
                           { 
                            auto pFrame=frame;
                            av_frame_free(&pFrame); }); });
    }
    ~VideoPlayer(){
        ac_play_destroy(_play);
    }


    void start(const char *url)
    {
        ac_play_start(_play, url, 0);
    }
    void stop()
    {
        ac_play_stop(_play);
    }
    void seek(double value){
        ac_play_seek(_play, value);
    }

    void setIsPaused(int value){
        ac_play_setIsPause(_play, value);
    }
    void setVolume(int value){
        ac_play_setVolume(_play, value);
    }
    void setSpeed(double value){
        ac_play_setSpeed(_play, value);
    }
  

    std::unique_ptr<flutter_video_player::Texture> texture;
    void *_play = nullptr;
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
        // handle->setIsDisableVideo(value);
    }

    void video_player_set_is_disable_audio(VideoPlayer *handle, int value)
    {
        // handle->setIsDisableAudio(value);
    }

    void video_player_set_video_track_index(VideoPlayer *handle, int value)
    {
        // handle->setVideoTrackIndex(value);
    }

    void video_player_set_audio_track_index(VideoPlayer *handle, int value)
    {
        // handle->setAudioTrackIndex(value);
    }

    int64_t video_player_get_texture_id(VideoPlayerHandle handle)
    {
        return handle->texture->getId();
    }

    void video_player_set_cursor_time_changed_callback(VideoPlayer *handle, CursorTimeChangedCallback callback, void *user_data)
    {
        // handle->onCursorTimeChanged = [=](Play *, CursorTimeChangedEventArgs *args)
        // {
        //     callback(handle, args->time, user_data);
        // };
    }
}
