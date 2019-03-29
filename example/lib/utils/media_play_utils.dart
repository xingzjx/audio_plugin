import 'dart:typed_data';

import 'package:audio_plugin/audio_plugin.dart';

class MediaPlayUtils {

  static AudioPlayer audioPlayer;

  static Future<void> play(var url) async {
    if(audioPlayer==null) {
      audioPlayer = new AudioPlayer();
    }
    if(url is String) {
      await audioPlayer.play(url);
    } else if(url is List) {
      await audioPlayer.playList(url);
    }
  }

  static Future<void> stop() async {
    if(audioPlayer!=null) {
      await audioPlayer.stop();
      audioPlayer = null;
    }

  }
}