package
{
	import away3dlite.animators.BonesAnimator;
	import away3dlite.containers.ObjectContainer3D;
	import away3dlite.containers.Scene3D;
	import away3dlite.core.base.Object3D;
	import away3dlite.events.Loader3DEvent;
	import away3dlite.loaders.Collada;
	import away3dlite.loaders.Loader3D;
	import away3dlite.materials.BitmapMaterial;
	
	import com.sleepydesign.utils.LoaderUtil;
	import com.sleepydesign.utils.URLUtil;
	
	import flars.FLARResult;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;
	import flash.utils.*;

	public class ModelViewer
	{
		private var _skinAnimation:BonesAnimator;
		
		private var _scene:Scene3D;
		
		private var _loader:Loader3D;
		private var _collada:Collada;
		private var _model:Object3D;
		private var _base:ObjectContainer3D;
		private var _root:ObjectContainer3D;
		
		public var _anchorA:Object3D;
		public var _anchorB:Object3D;
		public var _anchorC:Object3D;
		
		private var aa:Vector3D;
		private var bb:Vector3D;
		private var cc:Vector3D;
		
		public var visible:Boolean = true;
		
		public static var currentXML:XML;
		public static var currentURI:String;
		
		private var _texturePath:String;
		
		public function ModelViewer(scene:Scene3D)
		{
			_scene = scene;
			
			_anchorA = new Object3D();
			//_anchorA = new Sphere(new WireColorMaterial(0xFF0000), 50, 4, 4);
			scene.addChild(_anchorA);
			
			_anchorB = new Object3D();
			//_anchorB = new Sphere(new WireColorMaterial(0x00FF00), 50, 4, 4);
			scene.addChild(_anchorB);
			
			_anchorC = new Object3D();
			//_anchorC = new Sphere(new WireColorMaterial(0x0000FF), 50, 4, 4);
			scene.addChild(_anchorC);
			
			_base = new ObjectContainer3D();
			scene.addChild(_base);
			
			_root = new ObjectContainer3D();
			_base.addChild(_root);
			
			_root.x = Oishi.POSITION_X;
			_root.y = Oishi.POSITION_Y;
			_root.x = Oishi.POSITION_Z;
			
			/*
			_root.rotationX = Oishi.ROTATION_X;
			_root.rotationY = Oishi.ROTATION_Y;
			_root.rotationZ = Oishi.ROTATION_Z;
			*/
			
			_root.scaleX = Oishi.SCALE_X;
			_root.scaleY = Oishi.SCALE_Y;
			_root.scaleZ = Oishi.SCALE_Z;
		}
		
		public function get model():Object3D
		{
			return _model;
		}
		
		public function reset():void
		{
			if(_loader && _loader.parent)
			{
				_loader.parent.removeChild(_loader);
				_loader = null;
			}
		
			if(_model && _model.parent)
			{
				_model.parent.removeChild(_model);
				_model = null;
			}
			
			trace(" ! Model reset");
			//DebugUtil.addText("! Model reset");
		}
		
		public function setTexture(bitmap:Bitmap):void
		{
			trace(" * setTexture");
			_model.materialLibrary.currentMaterialData.material = new BitmapMaterial(bitmap.bitmapData);
		}
		
		public function parse(xml:XML):void
		{
			trace(" * Parse");
			
			currentXML = xml;
			
			_collada = new Collada();
			//_collada.bothsides = false;
			_collada.scaling = 40;
			
			reset();
			visible = false;
			
			_loader = new Loader3D();
			_loader.loadXML(xml, _collada, _texturePath);
			_loader.addEventListener(Loader3DEvent.LOAD_SUCCESS, onSuccess);
			_root.addChild(_loader);
		}
		
		public function load(uri:String):void
		{
			trace(" * load : " + uri);
			currentURI = uri;
			
			// gc
			if(_collada)
				_collada = null;
			
			_collada = new Collada();
			//_collada.bothsides = false;
			_collada.scaling = 40;
			
			reset();
			visible = false;
			
			if(URLUtil.getType(uri)=="bin")
			{
				var _paths:Array = uri.split("/");
				_paths.pop();
				_texturePath = _paths.join("/")+"/";
				
				LoaderUtil.loadCompress(uri, onLoadZIP);
			}else{
				_loader = new Loader3D();
				_loader.addEventListener(Loader3DEvent.LOAD_SUCCESS, onSuccess);
				_loader.addEventListener(Loader3DEvent.LOAD_ERROR, onError);
				_loader.loadGeometry(uri, _collada);
				_root.addChild(_loader);
			}
		}
		
		private function onLoadZIP(event:Event):void
		{
			if(event.type == Event.COMPLETE)
			{
				var _byte:ByteArray = ByteArray(event.target["data"]);
				var _xml:XML = new XML(_byte.readUTFBytes(_byte.length)); 
				parse(_xml);
			}
		}
		
		private function onError(event:Loader3DEvent):void
		{
			if(_loader.IOErrorText)
				trace("[IOError] : " + _loader.IOErrorText);
			
			trace("[ERROR] : " + event);
		}
		
		private function onSuccess(event:Loader3DEvent):void
		{
			trace("[Success] : " + event);
			
			visible = true;
			
			currentXML = new XML(_loader.data);
			
			_model = _loader.handle;
			/*
			_model.rotationX = -90;
			_model.rotationZ = -90;
			
			_model.scaleX = -1;
			_model.scaleZ = -1;
			*/
			
			_model.rotationX = Oishi.ROTATION_X+90;
			_model.rotationY = Oishi.ROTATION_Y;
			_model.rotationZ = Oishi.ROTATION_Z+90;
			
			try{
				_skinAnimation = _model.animationLibrary.getAnimation("default").animation as BonesAnimator;
			}catch(e:*){}
		}
		
		private var _temp:Object3D = new Object3D();
		private var _old:Object3D = new Object3D();
		public function setAxis(_FLARResult:FLARResult):void
		{
			_FLARResult.setTransform(_temp);
			
			//trace(int(_temp.rotationX), int(_temp.rotationY), int(_temp.rotationZ));
			if(Oishi.USE_LOCK_AXIS)
			{
				var rotationX_diff:Number = Math.abs(_old.rotationX-_temp.rotationX);
				var rotationY_diff:Number = Math.abs(_old.rotationY-_temp.rotationY);
				var rotationZ_diff:Number = Math.abs(_old.rotationZ-_temp.rotationZ);
				
				//trace(rotationX_diff, rotationZ_diff);
				
				if(rotationX_diff>180)
					_temp.rotationX = Math.abs(_temp.rotationX);
					
				if(rotationY_diff>180)
					_temp.rotationY = Math.abs(_temp.rotationY);
					
				if(rotationZ_diff>180)
					_temp.rotationZ = Math.abs(_temp.rotationZ);
			}
			
			_base.transform.matrix3D.interpolateTo(_temp.transform.matrix3D, Oishi.MATRIX3D_INTERPOLATE);
			_old.transform.matrix3D = _base.transform.matrix3D.clone();
		}
		
		public function setRefererPoint(p:Vector.<Number>):void
		{
			//p0
			_anchorA.x = p[0];
			_anchorA.y = -p[1];
			_anchorA.z = p[2];
			
			//p1.x < p2.x
			//p1.screenZ > p2.screenZ
			if(p[3]<p[6] && _anchorB.screenZ > _anchorC.screenZ)
			{
				//p1
				_anchorB.x = p[3];
				_anchorB.y = -p[4];
				_anchorB.z = p[5];
				//p2
				_anchorC.x = p[6];
				_anchorC.y = -p[7];
				_anchorC.z = p[8];
			}else{
				//p2
				_anchorB.x = p[6];
				_anchorB.y = -p[7];
				_anchorB.z = p[8];
				//p1
				_anchorC.x = p[3];
				_anchorC.y = -p[4];
				_anchorC.z = p[5];
			}
		}
		
		public function updateAnchor():void
		{
			// not dirty
			if(aa && aa.x == _anchorA.position.x)return;
			
			aa = _anchorA.position;
			bb = _anchorB.position;
			cc = _anchorC.position;
			
			_base.x = (aa.x + bb.x + cc.x)/3;
			_base.y = (aa.y + bb.y + cc.y)/3;
			_base.z = (aa.z + bb.z + cc.z)/3;
		}
		
		public function updateAnimation():void
		{
			try{
				if(_skinAnimation)
					_skinAnimation.update(getTimer()/1000);
			}catch(e:*){trace(e)};
		}
	}
}