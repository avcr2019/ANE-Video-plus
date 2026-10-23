package com.freshplanet.ane.AirVideo;

import android.content.Context;
import android.graphics.Color;
import android.net.Uri;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.StyledPlayerView;

public class CustomExoPlayerView extends FrameLayout implements Player.Listener {

    private ExoPlayer player;
    private StyledPlayerView playerView;
    private boolean isEnded = false;

    public interface OnVideoFinishListener {
        void onFinish();
    }

    private OnVideoFinishListener finishListener;

    public CustomExoPlayerView(Context context) {
        super(context);
        init(context);
    }

    private void init(Context context) {
        setBackgroundColor(Color.BLACK);

        // إنشاء محرك ExoPlayer
        player = new ExoPlayer.Builder(context).build();
        player.addListener(this);

        // واجهة العرض
        playerView = new StyledPlayerView(context);
        playerView.setPlayer(player);
        playerView.setUseController(true);
        playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL); // ملء الشاشة ومنع الحواف السوداء

        addView(playerView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
    }

    public void setOnFinishListener(OnVideoFinishListener listener) {
        this.finishListener = listener;
    }

    public void loadVideo(Uri uri) {
        if (player == null) return;
        isEnded = false;
        MediaItem mediaItem = MediaItem.fromUri(uri);
        player.setMediaItem(mediaItem);
        player.prepare();
        player.play();
    }

    public void pause() {
        if (player != null) player.pause();
    }

    public void resume() {
        if (player != null) {
            if (isEnded) {
                player.seekTo(0);
                isEnded = false;
            }
            player.play();
        }
    }

    public void replay() {
        if (player != null) {
            player.seekTo(0);
            player.play();
        }
    }

    public void showControls(boolean show) {
        if (playerView != null) {
            playerView.setUseController(show);
        }
    }

    public void releasePlayer() {
        if (player != null) {
            player.stop();
            player.release();
            player = null;
        }
        if (playerView != null) {
            playerView.setPlayer(null);
            playerView = null;
        }
    }

    @Override
    public void onPlaybackStateChanged(int playbackState) {
        if (playbackState == Player.STATE_ENDED) {
            isEnded = true;
            if (finishListener != null) {
                finishListener.onFinish();
            }
        }
    }
}
