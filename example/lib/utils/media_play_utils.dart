import 'dart:typed_data';

import 'package:audio_plugin/audio_plugin.dart';

class MediaPlayUtils {

  static AudioPlayer audioPlayer;

  static Future<void> play(List<String> url) async {
    if(audioPlayer==null) {
      audioPlayer = new AudioPlayer();
    }
    await audioPlayer.playList(url);

    Uint8List byteArray = null;

  }

  static Future<void> stop() async {
    if(audioPlayer!=null) {
      await audioPlayer.stop();
      audioPlayer = null;
    }

  }
}