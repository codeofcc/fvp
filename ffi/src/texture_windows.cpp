

#ifdef _WIN32
#include "texture.h"
#include <flutter/plugin_registrar_windows.h>
namespace flutter_video_player
{
	static flutter::TextureRegistrar *texture_registrar_;

	class _Texure : public Texture
	{
	public:
		_Texure() : texture(flutter::PixelBufferTexture(
						[=](size_t width, size_t height) -> const FlutterDesktopPixelBuffer *
						{
							return &buffer;
						}))
		{
			textureId = texture_registrar_->RegisterTexture(&texture);
			memset(&buffer, 0, sizeof(FlutterDesktopPixelBuffer));
		}
		~_Texure()
		{
		}
		virtual int64_t getId()
		{
			return textureId;
		}
		virtual void write(uint8_t *data, int width, int height)
		{
			buffer.width = width;
			buffer.height = height;
			buffer.buffer = data;
			texture_registrar_->MarkTextureFrameAvailable(textureId);
		}

	private:
		int64_t textureId;
		flutter::TextureVariant texture;
		FlutterDesktopPixelBuffer buffer;
	};

	void Texture::setTextureRegistrar(void *texture_registrar)
	{
		texture_registrar_ = (flutter::TextureRegistrar *)texture_registrar;
	}

	Texture *Texture::create()
	{
		return new _Texure;
	}
	void Texture::destory(Texture *texture, std::function<void()> onDestoried)
	{
		texture_registrar_->UnregisterTexture(texture->getId(), [=]()
											  {
		onDestoried();
		delete (_Texure*)texture; });
	}
}
#endif
