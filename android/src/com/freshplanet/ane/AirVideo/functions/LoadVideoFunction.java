package com.freshplanet.ane.AirVideo.functions;

import android.net.Uri;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.Extension;

public class LoadVideoFunction implements FREFunction
{
	@Override
	public FREObject call(FREContext context, FREObject[] args)
	{
		String url = null;
		try
		{
			url = args[0].getAsString();
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return null;
		}

		Uri uri = Uri.parse(url);
		Extension.context.setCurrentUri(uri);
		Extension.context.loadVideoUrl(uri);
		
		return null;
	}
}
