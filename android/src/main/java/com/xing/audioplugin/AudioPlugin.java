package com.xing.audioplugin;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.util.Log;

import java.io.IOException;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


public class AudioPlugin implements MethodCallHandler {
  private static final String ID = "audio_plugin";

  private final MethodChannel channel;
  private final AudioManager am;
  private final Handler handler = new Handler();
  private MediaPlayer mediaPlayer;
  private List<String> resources;

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), ID);
    channel.setMethodCallHandler(new AudioPlugin(registrar, channel));
  }

  private AudioPlugin(Registrar registrar, MethodChannel channel) {
    this.channel = channel;
    channel.setMethodCallHandler(this);
    Context context = registrar.context().getApplicationContext();
    this.am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result response) {
    switch (call.method) {
      case "play":
        play(call.argument("url").toString());
        response.success(null);
        break;
      case "playList":
        List<String> list = (List<String>) call.argument("url");
        // Log.w(ID, "playList:", list + "");
        play((List<String>) call.argument("url"));
        response.success(null);
        break;
      case "pause":
        pause();
        response.success(null);
        break;
      case "stop":
        stop();
        response.success(null);
        break;
      case "seek":
        double position = call.arguments();
        seek(position);
        response.success(null);
        break;
      case "mute":
        Boolean muted = call.arguments();
        mute(muted);
        response.success(null);
        break;
      default:
        response.notImplemented();
    }
  }

  private void mute(Boolean muted) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      am.adjustStreamVolume(AudioManager.STREAM_MUSIC, muted ? AudioManager.ADJUST_MUTE : AudioManager.ADJUST_UNMUTE, 0);
    } else {
      am.setStreamMute(AudioManager.STREAM_MUSIC, muted);
    }
  }

  private void seek(double position) {
    mediaPlayer.seekTo((int) (position * 1000));
  }

  private void stop() {
    handler.removeCallbacks(sendData);
    if (mediaPlayer != null) {
      mediaPlayer.stop();
      mediaPlayer.release();
      mediaPlayer = null;
      channel.invokeMethod("audio.onStop", null);
    }
  }

  private void pause() {
    handler.removeCallbacks(sendData);
    if (mediaPlayer != null) {
      mediaPlayer.pause();
      channel.invokeMethod("audio.onPause", true);
    }
  }

  private void play(List<String> list)  {
    this.resources = list;
    play(resources.get(0));
  }

  private void play(String url) {
    System.out.println("url======>" + url);
    if (mediaPlayer == null) {
      mediaPlayer = new MediaPlayer();
      mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

      try {
        mediaPlayer.setDataSource(url);
      } catch (IOException e) {
        Log.w(ID, "Invalid DataSource", e);
        channel.invokeMethod("audio.onError", "Invalid Datasource");
        return;
      }

      mediaPlayer.prepareAsync();

      mediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener(){
        @Override
        public void onPrepared(MediaPlayer mp) {
          mediaPlayer.start();
          channel.invokeMethod("audio.onStart", mediaPlayer.getDuration());
        }
      });

      mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener(){
        @Override
        public void onCompletion(MediaPlayer mp) {
          if(resources!=null) {
            resources.remove(0);
            System.out.println("======>" + resources);
            if(resources.size()==0) {// 队列出完表示结束播放了
              stop();
              channel.invokeMethod("audio.onComplete", null);
              resources = null;
            } else {
              play(resources.get(0));
            }
          } else {
            stop();
            channel.invokeMethod("audio.onComplete", null);
          }
        }
      });

      mediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener(){
        @Override
        public boolean onError(MediaPlayer mp, int what, int extra) {
          channel.invokeMethod("audio.onError", String.format("{\"what\":%d,\"extra\":%d}", what, extra));
          return true;
        }
      });
    } else {
      try {
        mediaPlayer.reset();
        mediaPlayer.setDataSource(url);
      } catch (IOException e) {
        Log.w(ID, "Invalid DataSource", e);
        channel.invokeMethod("audio.onError", "Invalid Datasource");
        return;
      }
      mediaPlayer.prepareAsync();
      // mediaPlayer.start();
      channel.invokeMethod("audio.onStart", mediaPlayer.getDuration());
    }
    handler.post(sendData);
  }

  private final Runnable sendData = new Runnable(){
    public void run(){
      try {
        if (!mediaPlayer.isPlaying()) {
          handler.removeCallbacks(sendData);
        }
        int time = mediaPlayer.getCurrentPosition();
        channel.invokeMethod("audio.onCurrentPosition", time);
        handler.postDelayed(this, 200);
      }
      catch (Exception e) {
        Log.w(ID, "When running handler", e);
      }
    }
  };
}

