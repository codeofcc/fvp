
import 'flutter_video_player_platform_interface.dart';

class FlutterVideoPlayer {
  Future<String?> getPlatformVersion() {
    return FlutterVideoPlayerPlatform.instance.getPlatformVersion();
  }
}
