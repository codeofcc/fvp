import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_video_player_platform_interface.dart';

/// An implementation of [FlutterVideoPlayerPlatform] that uses method channels.
class MethodChannelFlutterVideoPlayer extends FlutterVideoPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_video_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
