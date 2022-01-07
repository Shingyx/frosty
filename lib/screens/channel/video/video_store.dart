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
  WebViewController? controller;

  late Timer overlayTimer;
  late Timer updateTimer;

  @readonly
  var _menuVisible = true;

  @readonly
  var _paused = false;

  @readonly
  StreamTwitch? _streamInfo;

  final String userLogin;
  final AuthStore authStore;
  final SettingsStore settingsStore;

  _VideoStoreBase({
    required this.userLogin,
    required this.authStore,
    required this.settingsStore,
  }) {
    overlayTimer = Timer(const Duration(seconds: 3), () => _menuVisible = false);
    updateStreamInfo();
  }

  @action
  void handlePausePlay() {
    if (_paused) {
      controller?.runJavascript('document.getElementsByTagName("video")[0].play();');
    } else {
      controller?.runJavascript('document.getElementsByTagName("video")[0].pause();');
    }

    _paused = !_paused;
  }

  @action
  void handleVideoTap() {
    if (_menuVisible) {
      overlayTimer.cancel();

      _menuVisible = false;
    } else {
      overlayTimer.cancel();
      overlayTimer = Timer(const Duration(seconds: 5), () => _menuVisible = false);

      _menuVisible = true;

      updateStreamInfo();
    }
  }

  @action
  Future<void> updateStreamInfo() async {
    final updatedStreamInfo = await Twitch.getStream(userLogin: userLogin, headers: authStore.headersTwitch);
    if (updatedStreamInfo != null) {
      _streamInfo = updatedStreamInfo;
    }
  }

  @action
  void handleExpand() {
    overlayTimer.cancel();
    settingsStore.expandInfo = !settingsStore.expandInfo;
    overlayTimer = Timer(const Duration(seconds: 5), () => _menuVisible = false);
  }

  void handleRefresh() async {
    HapticFeedback.lightImpact();
    controller?.reload();
  }

  void initVideo() {
    try {
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
