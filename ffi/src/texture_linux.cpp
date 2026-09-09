#ifndef _WIN32
#include"platformTexture.h"
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>


struct _VideoOutletClass {
  FlPixelBufferTextureClass parent_class;
};
struct VideoOutletPrivate {
  int64_t texture_id = 0;
  uint8_t* buffer = nullptr;
  int32_t video_width = 0;
  int32_t video_height = 0;
};
G_DECLARE_DERIVABLE_TYPE(VideoOutlet, video_outlet, DART_VLC, VIDEO_OUTLET,
                         FlPixelBufferTexture)
G_DEFINE_TYPE_WITH_CODE(VideoOutlet, video_outlet,
                        fl_pixel_buffer_texture_get_type(),
                        G_ADD_PRIVATE(VideoOutlet))
static gboolean video_outlet_copy_pixels(FlPixelBufferTexture* texture,
                                         const uint8_t** out_buffer,
                                         uint32_t* width, uint32_t* height,
                                         GError** error) {
  auto video_outlet_private =
      (VideoOutletPrivate*)video_outlet_get_instance_private(
          DART_VLC_VIDEO_OUTLET(texture));
  *out_buffer = video_outlet_private->buffer;
  *width = video_outlet_private->video_width;
  *height = video_outlet_private->video_height;
  return TRUE;
}
static VideoOutlet* video_outlet_new() {
  return DART_VLC_VIDEO_OUTLET(g_object_new(video_outlet_get_type(), nullptr));
}
static void video_outlet_class_init(VideoOutletClass* klass) {
  FL_PIXEL_BUFFER_TEXTURE_CLASS(klass)->copy_pixels = video_outlet_copy_pixels;
}
static void video_outlet_init(VideoOutlet* self) {}


static FlTextureRegistrar* _registrar=nullptr;


class _Texure :public PlatformTexture
{
  friend class PlatformTexture;
public:
	_Texure() :_texture(
   video_outlet_new()
) {
	 fl_texture_registrar_register_texture(_registrar,FL_TEXTURE(_texture));
	}    
	~_Texure() {  
  g_object_unref(_texture);
	}
	virtual int64_t getId() {
		return (int64_t)_texture;
	}
	virtual void write(uint8_t* data, int width, int height) {


auto video_outlet_private =(VideoOutletPrivate*)video_outlet_get_instance_private(_texture);

video_outlet_private->video_width = width;
video_outlet_private->video_height = height;

video_outlet_private->buffer = data;

fl_texture_registrar_mark_texture_frame_available(_registrar, FL_TEXTURE(_texture));

	}
private:
	VideoOutlet* _texture;
};

void PlatformTexture::setTextureRegistrar(void* texture_registrar)
{
	_registrar = (FlTextureRegistrar*)texture_registrar;
}


PlatformTexture* PlatformTexture::create()
{
	return new _Texure;
}void PlatformTexture::destory(PlatformTexture* texture, std::function<void()> onDestoried)
{
   auto _texture=(_Texure*)texture;
   fl_texture_registrar_unregister_texture(_registrar,FL_TEXTURE(_texture->_texture));  
   	onDestoried();
  	delete _texture;
}

#endif