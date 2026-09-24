#include "include/fvp/fvp_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>
#include "texture.h"
#include <map>
#include <memory>
#include <sstream>

namespace
{

  class FvpPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

    FvpPlugin();

    virtual ~FvpPlugin();

  private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  };

  // static
  void FvpPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrar *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "fvp",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FvpPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
    flutter_video_player::Texture::setTextureRegistrar(registrar->texture_registrar());
  }

  FvpPlugin::FvpPlugin() {}

  FvpPlugin::~FvpPlugin() {}

  void FvpPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "eLinux";
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace

void FvpPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
  FvpPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrar>(registrar));
}
