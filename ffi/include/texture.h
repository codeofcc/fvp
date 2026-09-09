#pragma once
#include <stdint.h>
#include <functional>
#include <string>
namespace flutter_video_player
{
    class Texture
    {
    public:
        virtual ~Texture() {}
        static void setTextureRegistrar(void *);
        static Texture *create();
        static void destory(Texture *, std::function<void()> onDestoried);
        virtual int64_t getId() = 0;
        virtual void write(uint8_t *data, int width, int height) = 0;
    };
}
