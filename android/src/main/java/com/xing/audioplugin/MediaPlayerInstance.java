package com.xing.audioplugin;

/**
 * Copyright (C), 2015-2019, makeblock
 * FileName: MediaPlayUtils
 * Author: zhujinxing
 * Date: 2019/1/24 上午11:01
 * Description: ${DESCRIPTION}
 * History:
 * <author> <time> <version> <desc>
 * 作者姓名 修改时间 版本号 描述
 */

import android.content.res.AssetFileDescriptor;
import android.media.MediaPlayer;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;


/**
 * Created by junjie on 2016/3/31.
 */
public class MediaPlayerInstance {
    private MediaPlayer mediaPlayer;
    private List<String> resources;
    private int size;
    private IntenalOnCompletionListener myOnCompletionListener;
    private OnAllFinishListener allFinishListener;
    private OnFinishstener onFinishstener;
    private static MediaPlayerInstance mediaPlayerUtils = new MediaPlayerInstance();

    private MediaPlayerInstance() {

    }

    public static MediaPlayerInstance getInstance() {
        return mediaPlayerUtils;
    }

    public  void init(){
        if(mediaPlayer != null){
            return;
        }
        mediaPlayer = new MediaPlayer();
        resources = new ArrayList<>();
        myOnCompletionListener = new IntenalOnCompletionListener();
        mediaPlayer.setOnCompletionListener(myOnCompletionListener);
    }

    public  void release(){
        if(mediaPlayer == null){
            return;
        }
        mediaPlayer.setOnCompletionListener(null);
        if(mediaPlayer.isPlaying()){
            mediaPlayer.stop();
        }
        mediaPlayer.release();
        mediaPlayer = null;
        myOnCompletionListener = null;
        allFinishListener = null;
        onFinishstener = null;
        resources.clear();
        resources = null;
    }

    public void stop() {
        if(mediaPlayer ==null) return;
        mediaPlayer.stop();
    }

    public  void addresource(String resource, OnFinishstener onFinishstener){
        if(mediaPlayer == null){
            init();
        }
        //当前正在播放这条语音  或者   集合中已经有了这条语音，不重复播放
        if(mediaPlayer.isPlaying() || resources.contains(resource)){
            return;
        }
        this.onFinishstener = onFinishstener;
        resources.clear();
        resources.add(resource);
        readyPlayer();
    }

    public  void addresource(List<String> _resources, OnAllFinishListener allFinishListener){
        if(mediaPlayer == null){
            init();
        }
        size = _resources.size();
        //当前正在播放这条语音  或者   集合中已经有了这条语音，不重复播放
        if(mediaPlayer.isPlaying() || resources.contains(_resources)){
            return;
        }
        this.allFinishListener = allFinishListener;
        resources.clear();
        resources.addAll(_resources);
        readyPlayer();
    }

    public  void addresource(List<String> _resources, OnFinishstener onFinishstener){
        if(mediaPlayer == null){
            init();
        }
        size = _resources.size();
        //当前正在播放这条语音  或者   集合中已经有了这条语音，不重复播放
        if(mediaPlayer.isPlaying() || resources.contains(_resources)){
            return;
        }
        this.onFinishstener = onFinishstener;
        resources.clear();
        resources.addAll(_resources);
        readyPlayer();
    }

    private  void readyPlayer(){
        if(!mediaPlayer.isPlaying()){
            playAndSetData();
        }
    }

    private class IntenalOnCompletionListener implements MediaPlayer.OnCompletionListener {

        @Override
        public void onCompletion(MediaPlayer mp) {
            Log.e("MediaPlayerUtils" , resources.size() + " ");
            if(allFinishListener != null && resources.size() == 0 ) {
                allFinishListener.onFinish();
            }
            if(onFinishstener != null) {
                onFinishstener.onOneFinish(size - resources.size() - 1);
            }
            playAndSetData();
        }
    }

    private void playAndSetData(){
        try{
            if(resources.size() == 0) return;
            mediaPlayer.reset();
            String url = resources.get(0);
            if(url.startsWith("/") || url.startsWith("http")) {// sdcard or net
                mediaPlayer.setDataSource(url);
            } else {
                AssetFileDescriptor fd = Utils.getApp().getAssets().openFd(url);
                mediaPlayer.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
            }
            resources.remove(0);// 出队列
            mediaPlayer.prepareAsync();
            mediaPlayer.setOnPreparedListener(mp -> mediaPlayer.start());
        }catch (Exception e){
            e.printStackTrace();
        }
    }



    public interface OnAllFinishListener {
          void onFinish();
    }

    public interface OnFinishstener {
        void onOneFinish(int index);
    }
}
