#ifdef FLUTTER_PLATFORM_ELINUX
#include "texture.h"
#include "audioringbuffer.h"
#include <flutter/plugin_registrar.h>

namespace flutter_video_player
{

  static flutter::TextureRegistrar *texture_registrar_;

  struct _TextureBuffer
  {
    FlutterDesktopPixelBuffer buffer;
    std::function<void()> releaseCallback;

    ~_TextureBuffer()
    {
      if (releaseCallback)
      {
        releaseCallback();
      }
    }
  };

  class _Texure : public Texture
  {
  public:
    _Texure() : texture(flutter::PixelBufferTexture(
                    [=](size_t width, size_t height) -> const FlutterDesktopPixelBuffer *
                    {
                      // Clear stale buffers, keep only the latest one
                      while (_audioBuffer.available_read() > 1)
                      {
                        _TextureBuffer *buffer = nullptr;
                        if (_audioBuffer.read(&buffer, 1))
                        {
                          delete buffer;
                        }
                      }
                      // Get the latest buffer
                      _TextureBuffer *buffer = nullptr;
                      if (_audioBuffer.read(&buffer, 1))
                      {
                        return &buffer->buffer;
                      }
                      return nullptr;
                    }))
    {
      textureId = texture_registrar_->RegisterTexture(&texture);
    }

    ~_Texure()
    {
      texture_registrar_->UnregisterTexture(getId(), [=]()
                                            {
                                              _TextureBuffer *buffer = nullptr;
                                              while (_audioBuffer.read(&buffer, 1))
                                              {
                                                delete buffer;
                                              } });
    }

    virtual int64_t getId() override
    {
      return textureId;
    }

    virtual void write(uint8_t *data, int width, int height, const std::function<void()> &releaseCallback) override
    {
      _TextureBuffer *buffer = new _TextureBuffer;
      memset(buffer, 0, sizeof(_TextureBuffer));
      buffer->buffer.width = width;
      buffer->buffer.height = height;
      buffer->buffer.buffer = data;
      buffer->releaseCallback = releaseCallback;
      buffer->buffer.release_context = buffer;
      buffer->buffer.release_callback = [](void *buffer)
      {
        auto _buffer = (_TextureBuffer *)buffer;
        delete _buffer;
      };
      _audioBuffer.write(&buffer, 1);
      texture_registrar_->MarkTextureFrameAvailable(textureId);
    }

  private:
    int64_t textureId;
    flutter::TextureVariant texture;
    AudioRingBuffer<_TextureBuffer *, 8> _audioBuffer;
  };

  void Texture::setTextureRegistrar(void *texture_registrar)
  {
    texture_registrar_ = (flutter::TextureRegistrar *)texture_registrar;
  }

  Texture *Texture::create()
  {
    return new _Texure();
  }

} // namespace flutter_video_player
#endif
