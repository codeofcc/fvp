import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_video_player_method_channel.dart';

abstract class FlutterVideoPlayerPlatform extends PlatformInterface {
  /// Constructs a FlutterVideoPlayerPlatform.
  FlutterVideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterVideoPlayerPlatform _instance = MethodChannelFlutterVideoPlayer();

  /// The default instance of [FlutterVideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterVideoPlayer].
  static FlutterVideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterVideoPlayerPlatform] when
  /// they register themselves.
  static set instance(FlutterVideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
