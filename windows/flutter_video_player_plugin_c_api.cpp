#include "include/flutter_video_player/flutter_video_player_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_video_player_plugin.h"

void FlutterVideoPlayerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_video_player::FlutterVideoPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
