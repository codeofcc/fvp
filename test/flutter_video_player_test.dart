import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/flutter_video_player_platform_interface.dart';
import 'package:flutter_video_player/flutter_video_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterVideoPlayerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterVideoPlayerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterVideoPlayerPlatform initialPlatform = FlutterVideoPlayerPlatform.instance;

  test('$MethodChannelFlutterVideoPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterVideoPlayer>());
  });

  test('getPlatformVersion', () async {
    FlutterVideoPlayer flutterVideoPlayerPlugin = FlutterVideoPlayer();
    MockFlutterVideoPlayerPlatform fakePlatform = MockFlutterVideoPlayerPlatform();
    FlutterVideoPlayerPlatform.instance = fakePlatform;

    expect(await flutterVideoPlayerPlugin.getPlatformVersion(), '42');
  });
}
