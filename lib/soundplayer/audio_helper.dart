import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSuccess() async {
    await _player.play(AssetSource('audio/success.mp3'));
  }

  Future<void> playFailed() async {
    await _player.play(AssetSource('audio/failed.mp3'));
  }
}
