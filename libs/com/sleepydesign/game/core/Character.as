package com.sleepydesign.game.core
{
	import com.sleepydesign.events.SDEvent;
	import com.sleepydesign.game.data.CharacterData;
	import com.sleepydesign.game.core.AbstractCharacter;

	public class Character extends AbstractCharacter
	{
		private var data		:CharacterData;
		
		//public var instance		:DisplayObject3D;
		//public var model		:DisplayObject3D;
		
		//public var type			:String;
		//public var height		:Number=0;	
		
		public function Character(id:String=null)
		{
			super();
		}
		
		// ______________________________ Create ______________________________
		
		override public function create(config:Object=null):void
		{
			// try get character.model from object pool
			model = Characters.getInstance().getModel(config.src);
			instance.addChild(model.instance);
			model.instance.addEventListener(SDEvent.COMPLETE, onModelComplete);
		}
		
		private function onModelComplete(event:SDEvent):void
		{
			//instance.height = event.target.boundingBox().max.y;
			dispatchEvent(new SDEvent(SDEvent.COMPLETE));
		}
	}
}