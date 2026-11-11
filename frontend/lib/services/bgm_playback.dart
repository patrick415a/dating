import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BgmPlayback extends ChangeNotifier {
  BgmPlayback(this._assetPath, {required this.volume}) {
    _audio.onPlayerStateChanged.listen((_) => notifyListeners());
  }

  final String _assetPath;
  final double volume;
  final _audio = AudioPlayer();

  bool get isPlaying => _audio.state == PlayerState.playing;

  Future<void> play() async {
    if (_audio.state == PlayerState.paused) {
      await _audio.resume();
    } else {
      await _audio.setReleaseMode(ReleaseMode.loop);
      await _audio.setVolume(volume);
      await _audio.play(AssetSource(_assetPath));
    }
  }

  Future<void> pause() => _audio.pause();

  Future<void> stop() => _audio.stop();
}
