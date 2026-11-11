import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

class BgmPlayback extends ChangeNotifier {
  BgmPlayback(String assetPath, {required double volume}) {
    _audio
      ..preload = 'auto'
      ..loop = true
      ..volume = volume
      ..src = 'assets/assets/$assetPath';

    _audio.onPlaying.listen((_) => _setPlaying(!_audio.paused));
    _audio.onPause.listen((_) => _setPlaying(false));
    _audio.onEnded.listen((_) => _setPlaying(false));
    _audio.onError.listen((_) => _setPlaying(false));
  }

  final _audio = HTMLAudioElement();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> play() async {
    if (_audio.error != null) _audio.load();
    // Call play in the tap handler before waiting for any asset or audio context.
    await _audio.play().toDart;
  }

  Future<void> pause() async {
    _audio.pause();
    _setPlaying(false);
  }

  Future<void> stop() async {
    await pause();
    _audio.currentTime = 0;
  }

  void _setPlaying(bool value) {
    if (_isPlaying == value) return;
    _isPlaying = value;
    notifyListeners();
  }
}
