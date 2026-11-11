import 'package:flutter/foundation.dart';

import 'bgm_playback.dart' if (dart.library.js_interop) 'bgm_playback_web.dart';

class BgmPlayer extends ChangeNotifier {
  static final BgmPlayer _instance = BgmPlayer._internal();
  factory BgmPlayer() => _instance;
  BgmPlayer._internal() {
    _playback.addListener(notifyListeners);
  }

  final _playback = BgmPlayback('audios/family_and_love.mp3', volume: 0.3);
  bool _isBusy = false;
  bool _autoplayInProgress = false;
  bool _pausedByUser = false;

  bool get isPlaying => _playback.isPlaying;
  bool get isBusy => _isBusy || (!kIsWeb && _autoplayInProgress);

  Future<void> playBgm() async {
    // 화면 진입이나 웹 자동 재생 재시도가 사용자의 일시정지를 해제하지 않도록 합니다.
    if (isPlaying || _pausedByUser || isBusy || _autoplayInProgress) return;
    _autoplayInProgress = true;
    if (!kIsWeb) notifyListeners();
    try {
      await _playback.play();
    } catch (e) {
      debugPrint('BGM 재생 에러: $e');
    } finally {
      _autoplayInProgress = false;
      if (!kIsWeb) notifyListeners();
    }
  }

  Future<void> toggleBgm() async {
    if (isBusy) return;
    await _run(() async {
      if (isPlaying) {
        await _playback.pause();
        _pausedByUser = true;
      } else {
        await _playback.play();
        _pausedByUser = false;
      }
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    _isBusy = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> stopBgm() async {
    if (isBusy) return;
    await _run(() async {
      await _playback.stop();
      _pausedByUser = false;
    });
  }
}
