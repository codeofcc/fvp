import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'video_player_ffigen.dart';

/// 全局FFI绑定实例
final VideoPlayerFfigen _ffigen = VideoPlayerFfigen(DynamicLibrary.process());

/// 视频播放器控制器
///
/// 采用控件构建和销毁同步机制：
/// - 控件构建时自动播放
/// - 控件销毁时自动停止
class VideoPlayController {
  final VideoPlayerHandle _handle = _ffigen.video_player_create();
  final String _url;

  bool _isPaused = true;
  int _volume = 100;
  double _speed = 1.0;
  bool _disableVideo = false;
  bool _disableAudio = false;
  int _videoTrackIndex = 0;
  int _audioTrackIndex = 0;

  VideoPlayController(this._url);

  /// 视频地址
  String get url => _url;

  /// 纹理ID，用于Flutter渲染
  int get textureId => _ffigen.video_player_get_texture_id(_handle);

  /// 播放
  void play() {
    final urlPtr = _url.toNativeUtf8();
    try {
      _ffigen.video_player_start(_handle, urlPtr.cast());
    } finally {
      malloc.free(urlPtr);
    }
  }

  /// 暂停
  bool get isPaused => _isPaused;
  set isPaused(bool value) {
    _isPaused = value;

    _ffigen.video_player_set_is_paused(_handle, value ? 1 : 0);
  }

  /// 跳转到指定位置
  ///
  /// [position] 目标位置，单位秒
  void seekTo(double position) {
    _ffigen.video_player_seek(_handle!, position);
  }

  /// 音量 (0-100)
  int get volume => _volume;
  set volume(int value) {
    _volume = value.clamp(0, 100);

    _ffigen.video_player_set_volume(_handle, _volume);
  }

  /// 播放速度
  double get speed => _speed;
  set speed(double value) {
    _speed = value;

    _ffigen.video_player_set_speed(_handle, _speed);
  }

  /// 是否禁用视频
  bool get disableVideo => _disableVideo;
  set disableVideo(bool value) {
    _disableVideo = value;

    _ffigen.video_player_set_is_disable_video(_handle, value ? 1 : 0);
  }

  /// 是否禁用音频
  bool get disableAudio => _disableAudio;
  set disableAudio(bool value) {
    _disableAudio = value;

    _ffigen.video_player_set_is_disable_audio(_handle, value ? 1 : 0);
  }

  /// 视频轨道索引
  int get videoTrackIndex => _videoTrackIndex;
  set videoTrackIndex(int value) {
    _videoTrackIndex = value;

    _ffigen.video_player_set_video_track_index(_handle, _videoTrackIndex);
  }

  /// 音频轨道索引
  int get audioTrackIndex => _audioTrackIndex;
  set audioTrackIndex(int value) {
    _audioTrackIndex = value;

    _ffigen.video_player_set_audio_track_index(_handle, _audioTrackIndex);
  }

  /// 释放播放器资源
  ///
  /// 停止播放并销毁播放器实例
  void dispose() {
    _ffigen.video_player_destroy(_handle);
  }
}
