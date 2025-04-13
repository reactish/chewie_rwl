import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart' as video_player;
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:wakelock_plus/wakelock_plus.dart';

class OmniVideoController {
  final String url;
  final Map<String, String> httpHeaders;
  final bool backgroundPlayback;
  final bool mixAudio;
  late final OmniVideoValue value;

  late final media_kit.Player iosPlayer;
  late final media_kit_video.VideoController iosController;
  final Map<void Function(), StreamSubscription<dynamic>> _iosListeners = {};

  late final video_player.VideoPlayerController androidController;

  OmniVideoController({
    required this.url,
    this.httpHeaders = const {},
    this.backgroundPlayback = false,
    this.mixAudio = false,
  });

  Future<void> initialize() async {
    value = OmniVideoValue(this);

    if (Platform.isIOS) {
      iosPlayer = media_kit.Player();
      iosController = media_kit_video.VideoController(iosPlayer);
      await iosPlayer.open(media_kit.Media(url, httpHeaders: httpHeaders));
      value.iosInitialized = true;
    } else {
      androidController = video_player.VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: httpHeaders,
        videoPlayerOptions: video_player.VideoPlayerOptions(
          allowBackgroundPlayback: backgroundPlayback,
          mixWithOthers: mixAudio,
        ),
      );
      // todo probably initialize android manually ?? maybe idk
    }
    try {
      await WakelockPlus.enable();
    } catch (e) {
      // pass
    }
  }

  void dispose() async {
    try {
      if (Platform.isIOS) {
        await iosPlayer.dispose();
      } else {
        await androidController.dispose();
      }
    } catch (e) {
      // pass
    }
    try {
      await WakelockPlus.disable();
    } catch (e) {
      // pass
    }
  }

  void addPositionListener(void Function() listener) {
    if (Platform.isIOS) {
      final subscription = iosController.player.stream.position.listen(
        (_) => listener(),
      );
      _iosListeners[listener] = subscription;
    } else {
      androidController.addListener(listener);
    }
  }

  void removeListener(void Function() listener) {
    if (Platform.isIOS) {
      final subscription = _iosListeners.remove(listener);
      if (subscription != null) {
        subscription.cancel();
      }
    } else {
      androidController.removeListener(listener);
    }
  }

  Future<void> play() {
    if (Platform.isIOS) {
      return iosPlayer.play();
    } else {
      return androidController.play();
    }
  }

  Future<void> pause() {
    if (Platform.isIOS) {
      return iosPlayer.pause();
    } else {
      return androidController.pause();
    }
  }

  Future<void> seekTo(Duration position) {
    if (Platform.isIOS) {
      return iosPlayer.seek(position);
    } else {
      return androidController.seekTo(position);
    }
  }

  Future<void> setLooping(bool looping) {
    if (Platform.isIOS) {
      return iosPlayer.setPlaylistMode(
        looping ? media_kit.PlaylistMode.loop : media_kit.PlaylistMode.none,
      );
    } else {
      return androidController.setLooping(looping);
    }
  }

  Future<void> setVolume(double volume) {
    if (Platform.isIOS) {
      return iosPlayer.setVolume(volume * 100);
    } else {
      return androidController.setVolume(volume);
    }
  }
}

class OmniVideoValue {
  final OmniVideoController ctl;
  bool iosInitialized = false;

  OmniVideoValue(this.ctl);

  bool get isInitialized {
    if (Platform.isIOS) {
      return iosInitialized;
    } else {
      return ctl.androidController.value.isInitialized;
    }
  }

  bool get isPlaying {
    if (Platform.isIOS) {
      return ctl.iosPlayer.state.playing;
    } else {
      return ctl.androidController.value.isPlaying;
    }
  }

  Duration get duration {
    if (Platform.isIOS) {
      return ctl.iosPlayer.state.duration;
    } else {
      return ctl.androidController.value.duration;
    }
  }

  Duration get position {
    if (Platform.isIOS) {
      return ctl.iosPlayer.state.position;
    } else {
      return ctl.androidController.value.position;
    }
  }

  Size get size {
    if (Platform.isIOS) {
      final w = ctl.iosPlayer.state.width ?? 100;
      final h = ctl.iosPlayer.state.height ?? 100;
      return Size(w.toDouble(), h.toDouble());
    } else {
      return ctl.androidController.value.size;
    }
  }

  double get aspectRatio {
    if (Platform.isIOS) {
      final w = ctl.iosPlayer.state.width ?? 100;
      final h = ctl.iosPlayer.state.height ?? 100;
      return w.toDouble() / h.toDouble();
    } else {
      return ctl.androidController.value.aspectRatio;
    }
  }

  bool get isBuffering {
    if (Platform.isIOS) {
      return ctl.iosPlayer.state.buffering;
    } else {
      /// Gets the current buffering state of the video player.
      ///
      /// For Android, it will use a workaround due to a [bug](https://github.com/flutter/flutter/issues/165149)
      /// affecting the `video_player` plugin, preventing it from getting the
      /// actual buffering state. This currently results in the `VideoPlayerController` always buffering,
      /// thus breaking UI elements.
      ///
      /// For this, the actual buffer position is used to determine if the video is
      /// buffering or not. See Issue [#912](https://github.com/fluttercommunity/chewie/pull/912) for more details.
      if (ctl.androidController.value.isBuffering) {
        // -> Check if we actually buffer, as android has a bug preventing to
        //    get the correct buffering state from this single bool.
        final int position = ctl.androidController.value.position.inMilliseconds;

        // Special case, if the video is finished, we don't want to show the
        // buffering indicator anymore
        if (position >= ctl.androidController.value.duration.inMilliseconds) {
          return false;
        } else {
          final int buffer =
              ctl.androidController.value.buffered.lastOrNull?.end.inMilliseconds ?? -1;

          return position >= buffer;
        }
      } else {
        return false;
      }
    }
  }
}
