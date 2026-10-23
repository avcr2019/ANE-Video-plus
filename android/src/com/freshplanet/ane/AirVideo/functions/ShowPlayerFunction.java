package com.freshplanet.ane.AirVideo.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.Extension;

public class ShowPlayerFunction implements FREFunction
{
	@Override
	public FREObject call(FREContext context, FREObject[] args)
	{
		int x = -1;
		int y = -1;
		int width = -1;
		int height = -1;

		if (args != null && args.length >= 4)
		{
			try
			{
				x = args[0].getAsInt();
				y = args[1].getAsInt();
				width = args[2].getAsInt();
				height = args[3].getAsInt();
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}

		Extension.context.updatePlayerBounds(x, y, width, height);
		return null;
	}
}
