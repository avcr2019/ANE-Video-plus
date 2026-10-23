
package com.atlas4apps.ane.AirVideo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.system.Capabilities;

	public class AirVideo extends EventDispatcher
	{
		// --------------------------------------------------------------------------------------//
		// PUBLIC API
		// --------------------------------------------------------------------------------------//

		/** Event dispatched each time the currently played video changes. */
		public static const CURRENT_VIDEO_CHANGED : String = "CURRENT_VIDEO_CHANGED";

		/** AirVideo is supported on iOS and Android devices. */
		public static function get isSupported() : Boolean
		{
			var isIOS:Boolean = (Capabilities.manufacturer.indexOf("iOS") != -1);
			var isAndroid:Boolean = (Capabilities.manufacturer.indexOf("Android") != -1);
			return isIOS || isAndroid;
		}

		public function AirVideo()
		{
			if (!_instance)
			{
				_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);

				if (!_context)
				{
					log("ERROR - Extension context is null. Please check if extension.xml is setup correctly.");
					return;
				}

				_context.addEventListener(StatusEvent.STATUS, onStatus);
				_instance = this;
			}
			else
			{
				throw Error("This is a singleton, use getInstance(), do not call the constructor directly.");
			}
		}

		public static function getInstance() : AirVideo
		{
			return _instance ? _instance : new AirVideo();
		}

		/**
		 * If true, logs will be displayed at the Actionscript level.
		 * If false, logs will be displayed only at the native level.
		 */
		public function get logEnabled() : Boolean
		{
			return _logEnabled;
		}

		public function set logEnabled(value : Boolean) : void
		{
			_logEnabled = value;
		}

		/** Add the video player with optional coordinates and size. */
		public function showPlayer(
			x : int = -1,
			y : int = -1,
			width : int = -1,
			height : int = -1
		) : void
		{
			if (!isSupported) return;

			_context.call("showPlayer", x, y, width, height);
		}

		/** Dynamically change player bounds and position. */
		public function setPlayerBounds(
			x : int,
			y : int,
			width : int,
			height : int
		) : void
		{
			if (!isSupported) return;

			_context.call("setPlayerBounds", x, y, width, height);
		}

		/** Remove the video player from the display list. */
		public function hidePlayer() : void
		{
			if (!isSupported) return;

			_context.call("hidePlayer");
		}

		/** Pause the currently playing video. */
		public function pause() : void
		{
			if (!isSupported) return;

			_context.call("pause");
		}

		/** Resume playing the video. */
		public function resume() : void
		{
			if (!isSupported) return;

			_context.call("resume");
		}

		/** Replay video from beginning. */
		public function replay() : void
		{
			if (!isSupported) return;

			_context.call("replay");
		}

		/** Show or hide the native media controller bar. */
		public function showControls(value : Boolean) : void
		{
			if (!isSupported) return;

			_context.call("showControls", value);
		}

		/**
		 * Return the URL of the video being played currently,
		 * or null if nothing is playing.
		 */
		public function get currentVideo() : String
		{
			return _currentVideo ? _currentVideo.concat() : null;
		}

		/**
		 * Load and play a given video URL.
		 *
		 * If another video is currently being played, it will stop.
		 * Videos in the queue remain in the queue.
		 */
		public function loadVideo(url : String) : void
		{
			if (!isSupported) return;

			_context.call("loadVideo", url);
			setCurrentVideo(url);
		}

		/**
		 * Return an array containing the URLs of the videos currently
		 * in the queue. The currently played video is not included.
		 */
		public function get queue() : Array
		{
			return _queue.concat();
		}

		/**
		 * Append a video URL to the queue.
		 *
		 * If no video is currently playing and the queue is empty,
		 * the video is loaded and played directly.
		 */
		public function addVideoToQueue(url : String) : void
		{
			if (_currentVideo == null && _queue.length == 0)
				loadVideo(url);
			else
				_queue.push(url);
		}

		/** Remove all videos from the queue without stopping the current video. */
		public function clearQueue() : void
		{
			_queue.splice(0);
		}

		/** Stop the current video and start the first video in the queue, if any. */
		public function next() : void
		{
			if (_queue.length > 0)
			{
				var nextVideo:String = _queue[0];
				_queue.splice(0, 1);
				loadVideo(nextVideo);
			}
			else
			{
				setCurrentVideo(null);
			}
		}

		// --------------------------------------------------------------------------------------//
		// PRIVATE API
		// --------------------------------------------------------------------------------------//

		private static const EXTENSION_ID : String = "com.atlas4apps.AirVideo";

		private static var _instance : AirVideo;

		private var _context : ExtensionContext;
		private var _logEnabled : Boolean = false;
		private var _currentVideo : String;
		private var _queue : Array = [];

		private function setCurrentVideo(url : String) : void
		{
			if (url != _currentVideo)
			{
				_currentVideo = url ? url.concat() : null;
				dispatchEvent(new Event(CURRENT_VIDEO_CHANGED));
			}
		}

		private function onStatus(event : StatusEvent) : void
		{
			if (event.code == "PLAYBACK_DID_FINISH")
			{
				next();
			}
			else if (event.code == "LOGGING")
			{
				log(event.level);
			}
		}

		private function log(message : String) : void
		{
			if (_logEnabled)
				trace("[AirVideo] " + message);
		}
	}
}
