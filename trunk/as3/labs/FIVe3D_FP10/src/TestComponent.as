package
{
	import com.sleepydesign.display.SDSprite;
	import com.sleepydesign.net.LoaderUtil;
	
	import flash.display.Loader;

	[SWF(width="1132",height="654",frameRate="30",backgroundColor="#000000")]
	public class TestComponent extends SDSprite
	{
		public function TestComponent()
		{
			/*
			var _test:DialogBalloon = new DialogBalloon("1111111111111");
			_test.x=100;
			_test.y=100;
			addChild(_test);
			
			trace(Test.getFakeData())
			*/
			addChild(LoaderUtil.load("CandlePage.swf") as Loader);
		}
	}
}