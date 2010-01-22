package com.sleepydesign.site
{
	import com.sleepydesign.components.InputText;
	import com.sleepydesign.core.IDestroyable;
	import com.sleepydesign.data.DataProxy;
	import com.sleepydesign.events.FormEvent;
	import com.sleepydesign.events.RemovableEventDispatcher;
	import com.sleepydesign.net.LoaderUtil;
	import com.sleepydesign.system.DebugUtil;
	import com.sleepydesign.system.SystemUtil;
	import com.sleepydesign.utils.ObjectUtil;
	import com.sleepydesign.utils.StringUtil;
	import com.sleepydesign.utils.ValidationUtil;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.SimpleButton;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.utils.Dictionary;

	public class FormTool extends RemovableEventDispatcher implements IDestroyable
	{
		private var _container:DisplayObjectContainer;
		private var _xml:XML;
		private var _eventHandler:Function;

		private var _loader:Object /*URLLoader, Loader*/;
		private var _data:Object /*FormData*/;

		private var _items:Dictionary;

		private var _onInvalidCommand:String;
		private var _onIncompleteCommand:String;

		private var _alertText:TextField;

		public var returnType:* = URLVariables;

		public var isSubmit:Boolean = true;
		public var action:String;
		public var method:String = "GET";

		public function FormTool(container:DisplayObjectContainer, xml:XML = null, eventHandler:Function = null)
		{
			DebugUtil.trace("\n / [Form] ------------------------------- ");

			_container = container;
			_xml = xml;
			action = xml.@action;
			method = xml.@method;
			
			_eventHandler = eventHandler || trace;
			
			_onInvalidCommand = String(xml.@onInvalid);
			_onIncompleteCommand = String(xml.@onIncomplete);

			_items = new Dictionary(true);

			var _xmlList:XMLList = xml.children();
			var _xmlList_length:int = _xmlList.length();

			for (var i:uint = 0; i < _xmlList_length; i++)
			{
				var _itemXML:XML = _xmlList[i];
				var _name:String = String(_itemXML.name()).toLowerCase();
				var _containerID:String = StringUtil.getDefaultIfNull(_itemXML.@src, String(_itemXML.@id));

				DebugUtil.trace("   + " + _name + "\t: " + _containerID);

				var _textField:TextField;
				var item:InputText;

				switch (_name)
				{
					case "textfield":
						_textField = _container.getChildByName(_containerID) as TextField;
						if (String(_itemXML.@type) == "alert")
							_alertText = _textField;
						break;
					case "textinput":
						_textField = _container.getChildByName(_containerID) as TextField;
						item = new InputText(_textField.text, _textField);
						if (item)
						{
							item.defaultText = (String(_itemXML.@label) != "") ? String(_itemXML.@label) : item.text;
							item.defaultText = (String(_itemXML.text()) != "") ? String(_itemXML.text()) : item.defaultText;
							item.text = item.defaultText;

							item.text = (String(_itemXML.@value) != "") ? String(_itemXML.@value) : item.text;

							item.id = String(_itemXML.@id);
							item.isRequired = Boolean(String(_itemXML.@required) == "true");
							item.disable = Boolean(String(_itemXML.@disable) == "true");
							item.type = String(_itemXML.@type);

							item.isReset = Boolean(String(_itemXML.@reset) == "true");

							item.maxChars = !StringUtil.isNull(_itemXML.@maxlength) ? int(_itemXML.@maxlength) : 0;
							item.restrict = !StringUtil.isNull(_itemXML.@restrict) ? String(_itemXML.@restrict) : null;

							item.label.removeEventListener(FocusEvent.FOCUS_IN, focusListener);
							item.label.addEventListener(FocusEvent.FOCUS_IN, focusListener);

							//reg
							_items[String(_itemXML.@id)] = item;
						}
						break;
					case "button":
						var button:SimpleButton = SimpleButton(_container.getChildByName(_containerID));

						switch (String(_itemXML.@type))
					{
						case "save":
							isSubmit = false;
						case "submit":
							button.removeEventListener(MouseEvent.CLICK, buttonHandler);
							button.addEventListener(MouseEvent.CLICK, buttonHandler);
							break;
					}

						button.visible = (String(_itemXML.@visible) != "false");
						break;
				}
			}
			DebugUtil.trace(" ------------------------------- [Form] /\n");
		}

		// ____________________________________________ Field ____________________________________________

		private function focusListener(event:FocusEvent):void
		{
			var item:* = event.currentTarget;

			switch (event.type)
			{
				case FocusEvent.FOCUS_IN:
					if (item.text == item.parent.defaultText)
						item.text = "";

					switch (item.parent.type)
				{
					case "password":
						item.text = "";
						item.displayAsPassword = true;
						break;
				}
					item.parent.setText(item.text);
					event.currentTarget.addEventListener(FocusEvent.FOCUS_OUT, focusListener);
					break;
				case FocusEvent.FOCUS_OUT:

					if (item.text == "")
					{
						item.text = item.parent.defaultText;
						item.displayAsPassword = false;
					}
					item.parent.setText(item.text);
					event.currentTarget.removeEventListener(FocusEvent.FOCUS_OUT, focusListener);
					break;
			}
		}

		// ____________________________________________ Button ____________________________________________

		private function buttonHandler(event:MouseEvent):void
		{
			DebugUtil.trace(" ^ " + event.type);
			_data = validateData();

			if (_data)
				submit();
		/*else
		   {
		   var _formEvent:FormEvent = new FormEvent(FormEvent.INVALID, {items: _items});
		   dispatchEvent(_formEvent);
		   _eventHandler(_formEvent);
		 }*/
		}

		// ____________________________________________ Validate ____________________________________________

		private function validateData():URLVariables
		{
			var formData:URLVariables = new URLVariables();
			var isRequired:Boolean = false;
			var isComplete:Boolean = true;
			var isValid:Boolean = true;
			var input:*

			var _formEvent:FormEvent;
			var _inCompleteList:Array = [];
			var _inValidNameList:Array = [];

			// fill all?
			for each (input in _items)
			{
				//is edit?
				input.isEdit = (input.text != input.defaultText) && (input.text != "");

				// all edit mean complete
				isComplete = isComplete && input.isEdit;

				// only 1 required mean required
				isRequired = isRequired || input.isRequired;

				if (!input.isEdit && input.isRequired)
					_inCompleteList.push(input);
			}

			if (isRequired)
			{
				if (!isComplete)
				{
					/*
					   _formEvent = new FormEvent(FormEvent.INCOMPLETE, {items: _items});
					   dispatchEvent(_formEvent);
					   _eventHandler(_formEvent);
					 */

					showIncomplete(_inCompleteList);

					// no mercy!
					return null;
				}
			}

			//collect input
			for each (input in _items)
			{
				//reset
				input.isValid = false;

				//is edit?
				input.isEdit = (input.text != input.defaultText) && (input.text != "");
				if (input.isEdit)
				{
					//validate
					switch (input.type)
					{
						case "email":
							input.isValid = ValidationUtil.validateEmail(input.text);
							break;
						default:
							input.isValid = ValidationUtil.validateString(input.text);
							break;
					}
				}
				else
				{
					//not fill yet
					if (input.isRequired)
					{
						isValid = false;
						showIncomplete(input);
					}
				}

				if (input.isValid)
				{
					if (input.isEdit)
						formData[input.id] = input.text;
				}
				else
				{
					_inValidNameList.push(input.defaultText);
				}

				//clear
				if (input.isEdit)
				{
					switch (input.type)
					{
						case "password":
							input.text = input.defaultText;
							break;
					}
				}

				isValid = input.isValid && isValid;
			}

			//finally!
			if (isValid)
			{
				return formData;
			}
			else
			{
				showInvalid(_inValidNameList);
				return null;
			}
		}

		public function alert(msg:String):void
		{
			if (_alertText)
				_alertText.htmlText = msg;
		}

		private function showIncomplete(items:Array):void
		{
			DebugUtil.trace(" ! Incomplete");

			if (_onIncompleteCommand)
				SystemUtil.doCommand(_onIncompleteCommand, this);

			var _formEvent:FormEvent = new FormEvent(FormEvent.INCOMPLETE, {items: items});
			dispatchEvent(_formEvent);
			_eventHandler(_formEvent);

		}

		private function showInvalid(items:Array):void
		{
			DebugUtil.trace(" ! Invalid");

			if (_onInvalidCommand)
				SystemUtil.doCommand(StringUtil.replace(_onInvalidCommand, "$invalid_list", items.join(",")), this);

			var _formEvent:FormEvent = new FormEvent(FormEvent.INVALID, {items: items});
			dispatchEvent(_formEvent);
			_eventHandler(_formEvent);
		}

		// ____________________________________________ Action ____________________________________________

		public function submit():void
		{
			var url:String = action;

			//external get data
			if (!StringUtil.isNull(_xml.@get))
			{
				var _externalGETData:URLVariables = DataProxy.getDataByVars(_xml.@get);
				if (url.split("#")[0].indexOf("?") > -1)
					url += "&" + _externalGETData.toString();
			}

			//external post data
			if (!StringUtil.isNull(_xml.@post))
			{
				var _externalPOSTData:URLVariables = DataProxy.getDataByVars(_xml.@post);
				_data = ObjectUtil.addValue(_data, _externalPOSTData);
			}

			DebugUtil.trace(ObjectUtil.toString(_data));

			LoaderUtil.SEND_METHOD = method;

			var _formEvent:FormEvent = new FormEvent(FormEvent.COMPLETE, _data);
			dispatchEvent(_formEvent);
			_eventHandler(_formEvent);

			if (isSubmit)
			{
				trace(" * Submit");
				if (returnType == URLVariables)
				{
					_loader = LoaderUtil.requestVars(url, _data, onGetFormData);
				}
				else
				{
					_loader = LoaderUtil.request(url, _data, onGetFormData);
				}

				_formEvent = new FormEvent(FormEvent.SUBMIT, _data);
				dispatchEvent(_formEvent);
				_eventHandler(_formEvent);
			}
		}

		// ____________________________________________ Server Data ____________________________________________

		private function onGetFormData(event:Event):void
		{
			//if(useDebug)
			trace(" ^ onGetFormData\t: " + event);
			if (event.type != Event.COMPLETE && event.type != DataEvent.DATA)
				return;

			// reset?
			for each (var input:*in _items)
				if (input.isReset)
					input.text = input.defaultText;

			// form data event
			//var _dataEvent:DataEvent = new DataEvent(DataEvent.DATA, false, false, event.target.data);
			dispatchEvent(event);
			_eventHandler(event);
		}

		// ____________________________________________ Destroy ____________________________________________

		override public function destroy():void
		{
			super.destroy();

			_container = null;
			_xml = null;
			_eventHandler = null;

			_loader = null;
			_data = null;

			_items = null;

			_alertText = null;
		}
	}
}