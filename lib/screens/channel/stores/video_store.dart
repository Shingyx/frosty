import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:frosty/api/twitch_api.dart';
import 'package:frosty/core/auth/auth_store.dart';
import 'package:frosty/models/stream.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'video_store.g.dart';

class VideoStore = _VideoStoreBase with _$VideoStore;

abstract class _VideoStoreBase with Store {
  final TwitchApi twitchApi;

  WebViewController? controller;

  late Timer _overlayTimer;

  @readonly
  var _paused = true;

  @readonly
  var _overlayVisible = true;

  @readonly
  StreamTwitch? _streamInfo;

  @computed
  String get videoUrl => settingsStore.showOverlay
      ? 'https://player.twitch.tv/?channel=$userLogin&controls=false&muted=false&parent=frosty'
      : 'https://player.twitch.tv/?channel=$userLogin&muted=false&parent=frosty';

  late final javascriptChannels = {
    JavascriptChannel(
      name: 'Pause',
      onMessageReceived: (message) => _paused = true,
    ),
    JavascriptChannel(
      name: 'Play',
      onMessageReceived: (message) => _paused = false,
    ),
  };

  final String userLogin;
  final AuthStore authStore;
  final SettingsStore settingsStore;

  _VideoStoreBase({
    required this.userLogin,
    required this.twitchApi,
    required this.authStore,
    required this.settingsStore,
  }) {
    _overlayTimer = Timer(const Duration(seconds: 3), () => _overlayVisible = false);
    updateStreamInfo();
  }

  @action
  void handlePausePlay() {
    try {
      if (_paused) {
        controller?.runJavascript('document.getElementsByTagName("video")[0].play();');
      } else {
        controller?.runJavascript('document.getElementsByTagName("video")[0].pause();');
      }

      _paused = !_paused;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @action
  void handleVideoTap() {
    _overlayTimer.cancel();

    if (_overlayVisible) {
      _overlayVisible = false;
    } else {
      updateStreamInfo();

      _overlayVisible = true;
      _overlayTimer = Timer(const Duration(seconds: 5), () => _overlayVisible = false);
    }
  }

  @action
  Future<void> updateStreamInfo() async {
    try {
      _streamInfo = await twitchApi.getStream(userLogin: userLogin, headers: authStore.headersTwitch);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @action
  void handleExpand() {
    settingsStore.expandInfo = !settingsStore.expandInfo;

    _overlayTimer.cancel();
    _overlayTimer = Timer(const Duration(seconds: 5), () => _overlayVisible = false);
  }

  @action
  Future<void> handleToggleOverlay() async {
    if (settingsStore.toggleableOverlay) {
      settingsStore.showOverlay = !settingsStore.showOverlay;

      await controller?.loadUrl(videoUrl);

      if (settingsStore.showOverlay) {
        _overlayVisible = true;

        _overlayTimer.cancel();
        _overlayTimer = Timer(const Duration(seconds: 3), () => _overlayVisible = false);
      }
    }
  }

  void handleRefresh() {
    HapticFeedback.lightImpact();
    controller?.reload();
  }

  FutureOr<NavigationDecision> handleNavigation(NavigationRequest navigation) {
    if (navigation.url.startsWith('https://player.twitch.tv')) {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent;
  }

  void initVideo() {
    try {
      controller?.runJavascript('document.getElementsByTagName("video")[0].addEventListener("pause", () => Pause.postMessage("video paused"));');
      controller?.runJavascript('document.getElementsByTagName("video")[0].addEventListener("play", () => Play.postMessage("video playing"));');
      controller?.runJavascript('document.getElementsByTagName("video")[0].muted = false;');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void requestPictureInPicture() {
    try {
      controller?.runJavascript('document.getElementsByTagName("video")[0].requestPictureInPicture();');
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}