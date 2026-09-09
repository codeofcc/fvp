import 'package:flutter/widgets.dart';

import 'video_player_controller.dart';
import 'dispose_detector.dart';

/// 视频播放器Widget
///
/// [controller] 播放器控制器，由外部管理生命周期
class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayController controller;

  const VideoPlayerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StateDetector<Widget, VideoPlayController>(
      onInitState: () {
        controller.play();
      },
      onDispose: () {
        controller.dispose();
      },
      onDidUpdateWidget: (state) {
        if (controller != state.tag) {
          state.tag?.dispose();
        }
        else{
          print("controller is same");
        }
        controller.play();
      },
      tag: controller,
      child: Texture(textureId: controller.textureId),
    );
  }
}
