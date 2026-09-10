#ifdef FLUTTER_PLATFORM_LINUX
#include "texture.h"
#include "audioringbuffer.h"
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
namespace flutter_video_player
{
  struct _TextureBuffer
  {
    uint8_t *buffer;
    int width;
    int height;
    std::function<void()> releaseCallback;
    _TextureBuffer() : buffer(nullptr), width(0), height(0) {}
    ~_TextureBuffer()
    {
      if (releaseCallback)
      {
        releaseCallback();
      }
    }
  };

  struct _VideoOutletClass
  {
    FlPixelBufferTextureClass parent_class;
  };
  struct VideoOutletPrivate
  {
    int64_t texture_id = 0;
    uint8_t *buffer = nullptr;
    int32_t video_width = 0;
    int32_t video_height = 0;
    AudioRingBuffer<_TextureBuffer *, 8> *_audioBuffer = nullptr;
  };
  G_DECLARE_DERIVABLE_TYPE(VideoOutlet, video_outlet, DART_VLC, VIDEO_OUTLET,
                           FlPixelBufferTexture)
  G_DEFINE_TYPE_WITH_CODE(VideoOutlet, video_outlet,
                          fl_pixel_buffer_texture_get_type(),
                          G_ADD_PRIVATE(VideoOutlet))

  static gboolean video_outlet_copy_pixels(FlPixelBufferTexture *texture,
                                           const uint8_t **out_buffer,
                                           uint32_t *width, uint32_t *height,
                                           GError **error)
  {
    auto video_outlet_private =
        (VideoOutletPrivate *)video_outlet_get_instance_private(
            DART_VLC_VIDEO_OUTLET(texture));

    // 清理多余的 buffer，只保留最新的
    while (video_outlet_private->_audioBuffer->available_read() > 1)
    {
      _TextureBuffer *old_buffer = nullptr;
      video_outlet_private->_audioBuffer->read(&old_buffer, 1);
      delete old_buffer;
    }

    // 获取最新的 buffer
    _TextureBuffer *buffer = nullptr;
    if (video_outlet_private->_audioBuffer->read(&buffer, 1))
    {
      *out_buffer = buffer->buffer;
      *width = buffer->width;
      *height = buffer->height;
      // buffer 会在 Flutter 使用完后通过 releaseCallback 释放
    }
    return TRUE;
  }
  static VideoOutlet *video_outlet_new()
  {
    return DART_VLC_VIDEO_OUTLET(g_object_new(video_outlet_get_type(), nullptr));
  }
  static void video_outlet_class_init(VideoOutletClass *klass)
  {
    FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = video_outlet_copy_pixels;
  }
  static void video_outlet_init(VideoOutlet *self)
  {
    auto video_outlet_private =
        (VideoOutletPrivate *)video_outlet_get_instance_private(self);
    video_outlet_private->_audioBuffer = new AudioRingBuffer<_TextureBuffer *, 8>();
  }

  static FlTextureRegistrar *_registrar = nullptr;

  class _Texure : public Texture
  {
    friend class Texture;

  public:
    _Texure() : _texture(
                    video_outlet_new())
    {
      auto video_outlet_private =
          (VideoOutletPrivate *)video_outlet_get_instance_private(_texture);
      fl_texture_registrar_register_texture(_registrar, FL_TEXTURE(_texture));
      video_outlet_private->texture_id = (int64_t)_texture;
    }
    ~_Texure()
    {
      auto video_outlet_private =
          (VideoOutletPrivate *)video_outlet_get_instance_private(_texture);
      // 清空 ring buffer 并释放所有 buffer
      _TextureBuffer *buffer = nullptr;
      while (video_outlet_private->_audioBuffer->read(&buffer, 1))
      {
        delete buffer;
      }
      delete video_outlet_private->_audioBuffer;
      fl_texture_registrar_unregister_texture(_registrar, FL_TEXTURE(_texture));
      g_object_unref(_texture);
    }
    virtual int64_t getId() override
    {
      return (int64_t)_texture;
    }
    virtual void write(uint8_t *data, int width, int height, const std::function<void()> &releaseCallback) override
    {
      auto video_outlet_private =
          (VideoOutletPrivate *)video_outlet_get_instance_private(_texture);

      _TextureBuffer *buffer = new _TextureBuffer();
      buffer->buffer = data;
      buffer->width = width;
      buffer->height = height;
      buffer->releaseCallback = releaseCallback;

      video_outlet_private->_audioBuffer->write(&buffer, 1);
      fl_texture_registrar_mark_texture_frame_available(_registrar, FL_TEXTURE(_texture));
    }

  private:
    VideoOutlet *_texture;
  };

  void Texture::setTextureRegistrar(void *texture_registrar)
  {
    _registrar = (FlTextureRegistrar *)texture_registrar;
  }

  Texture *Texture::create()
  {
    return new _Texure;
  }
}
#endif