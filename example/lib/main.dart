import 'package:audio_plugin_example/utils/contants.dart';
import 'package:audio_plugin_example/utils/file_utils.dart';
import 'package:audio_plugin_example/utils/media_play_utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:audio_plugin/audio_plugin.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();

  }


  Future<ByteData> loadAsset() async {
    return await rootBundle.load('assets/1.mp3');
  }


  Future<void> playAudio() async {
    List<String> list = new List();
    list.add("CASE.mp3");
    list.add("BODD.mp3");
    list.add("http://ra01.sycdn.kuwo.cn/resource/n3/32/56/3260586875.mp3");
    list.add("ADAN.mp3");
    list.add(await FileUtils.getPathByName("username/CODY.mp3"));
    list.add(await FileUtils.getPathByName("username/ALEX.mp3"));
//    list.add(await FileUtils.getPathByName("username/ABEL.mp3"));
//    list.add(await FileUtils.getPathByName("username/COLE.mp3"));
//    list.add(await FileUtils.getPathByName("username/COLBY.mp3"));
    MediaPlayUtils.play(list);
  }

  Future<void> stop() async {
    MediaPlayUtils.stop();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: (){
                playAudio();
              },
              child: Text("播放"),
            ),
            RaisedButton(
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: (){
                stop();
              },
              child: Text("停止"),
            ),
          ],
        ),),
      ),
    );
  }
}
