package com.freshplanet.ane.AirVideo;

import java.util.HashMap;
import java.util.Map;

import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.functions.HidePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.LoadVideoFunction;
import com.freshplanet.ane.AirVideo.functions.SetPlayerBoundsFunction;
import com.freshplanet.ane.AirVideo.functions.ShowPlayerFunction;

public class ExtensionContext extends FREContext implements CustomExoPlayerView.OnVideoFinishListener
{
	private CustomExoPlayerView _exoView = null;
	private ViewGroup _videoContainer = null;
	private Uri _currentUri = null;
	private boolean _showControls = true;

	public void setCurrentUri(Uri uri) {
		_currentUri = uri;
	}

	@Override
	public void dispose() {
		hidePlayer();
	}

	@Override
	public Map<String, FREFunction> getFunctions()
	{
		Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
		
		functions.put("showPlayer", new ShowPlayerFunction());
		functions.put("hidePlayer", new HidePlayerFunction());
		functions.put("loadVideo", new LoadVideoFunction());
		functions.put("setPlayerBounds", new SetPlayerBoundsFunction());

		functions.put("pause", new FREFunction() {
			@Override
			public FREObject call(FREContext context, FREObject[] args) {
				if (getActivity() != null) {
					getActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							if (_exoView != null) {
								_exoView.pause();
							}
						}
					});
				}
				return null;
			}
		});

		functions.put("resume", new FREFunction() {
			@Override
			public FREObject call(FREContext context, FREObject[] args) {
				if (getActivity() != null) {
					getActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							if (_exoView != null) {
								_exoView.resume();
							}
						}
					});
				}
				return null;
			}
		});

		functions.put("replay", new FREFunction() {
			@Override
			public FREObject call(FREContext context, FREObject[] args) {
				if (getActivity() != null) {
					getActivity().runOnUiThread(new Runnable() {
						@Override
						public void run() {
							if (_exoView != null) {
								_exoView.replay();
							}
						}
					});
				}
				return null;
			}
		});

		functions.put("showControls", new FREFunction() {
			@Override
			public FREObject call(FREContext context, FREObject[] args) {
				try {
					final boolean show = args[0].getAsBool();
					_showControls = show;
					if (getActivity() != null) {
						getActivity().runOnUiThread(new Runnable() {
							@Override
							public void run() {
								if (_exoView != null) {
									_exoView.showControls(show);
								}
							}
						});
					}
				} catch (Exception e) {
					e.printStackTrace();
				}
				return null;
			}
		});
		
		return functions;
	}
	
	public ViewGroup getRootContainer()
	{
		return (ViewGroup)((ViewGroup)getActivity().findViewById(android.R.id.content)).getChildAt(0);
	}
	
	public ViewGroup getVideoContainer()
	{
		if (_videoContainer == null)
		{
			_videoContainer = new FrameLayout(getActivity());
			_videoContainer.setBackgroundColor(Color.BLACK);
			_videoContainer.addView(getExoView(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
		}
		return _videoContainer;
	}
	
	public CustomExoPlayerView getExoView()
	{
		if (_exoView == null)
		{
			_exoView = new CustomExoPlayerView(getActivity());
			_exoView.showControls(_showControls);
			_exoView.setOnFinishListener(this);
		}
		return _exoView;
	}

	public void updatePlayerBounds(final int x, final int y, final int width, final int height)
	{
		if (getActivity() == null) return;

		getActivity().runOnUiThread(new Runnable()
		{
			@Override
			public void run()
			{
				ViewGroup root = getRootContainer();
				ViewGroup container = getVideoContainer();

				FrameLayout.LayoutParams params;
				if (width > 0 && height > 0)
				{
					params = new FrameLayout.LayoutParams(width, height);
				}
				else
				{
					params = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
				}

				if (x >= 0 && y >= 0)
				{
					params.gravity = Gravity.TOP | Gravity.LEFT;
					params.leftMargin = x;
					params.topMargin = y;
				}
				else
				{
					params.gravity = Gravity.CENTER;
				}

				if (container.getParent() == null)
				{
					root.addView(container, params);
				}
				else
				{
					container.setLayoutParams(params);
				}
			}
		});
	}

	public void loadVideoUrl(final Uri uri) {
		if (getActivity() == null) return;
		getActivity().runOnUiThread(new Runnable() {
			@Override
			public void run() {
				getExoView().loadVideo(uri);
			}
		});
	}

	public void hidePlayer()
	{
		if (getActivity() == null) return;

		getActivity().runOnUiThread(new Runnable()
		{
			@Override
			public void run()
			{
				ViewGroup root = getRootContainer();
				ViewGroup container = getVideoContainer();
				
				if (_exoView != null) {
					_exoView.releasePlayer();
				}

				if (container != null && container.getParent() != null)
				{
					root.removeView(container);
				}

				_exoView = null;
				_videoContainer = null;
			}
		});
	}
	
	@Override
	public void onFinish()
	{
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}
}
