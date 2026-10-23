package com.freshplanet.ane.AirVideo;

import android.content.Context;
import android.widget.VideoView;

public class CustomVideoView extends VideoView {

    public CustomVideoView(Context context) {
        super(context);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int width = getDefaultSize(0, widthMeasureSpec);
        int height = getDefaultSize(0, heightMeasureSpec);
        setMeasuredDimension(width, height);
    }
}
