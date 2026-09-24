
import 'fvp_platform_interface.dart';
export 'src/video_player_controller.dart';
export 'src/video_player_widget.dart';
class Fvp {
  Future<String?> getPlatformVersion() {
    return FvpPlatform.instance.getPlatformVersion();
  }
}
