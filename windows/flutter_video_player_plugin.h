#ifndef FLUTTER_PLUGIN_FLUTTER_VIDEO_PLAYER_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_VIDEO_PLAYER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_video_player {

class FlutterVideoPlayerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterVideoPlayerPlugin();

  virtual ~FlutterVideoPlayerPlugin();

  // Disallow copy and assign.
  FlutterVideoPlayerPlugin(const FlutterVideoPlayerPlugin&) = delete;
  FlutterVideoPlayerPlugin& operator=(const FlutterVideoPlayerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_video_player

#endif  // FLUTTER_PLUGIN_FLUTTER_VIDEO_PLAYER_PLUGIN_H_
