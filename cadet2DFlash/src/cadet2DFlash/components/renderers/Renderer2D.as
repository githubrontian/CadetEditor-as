// =================================================================================================
//
//	CadetEngine Framework
//	Copyright 2012 Unwrong Ltd. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package cadet2DFlash.components.renderers
{
	import cadet.core.Component;
	import cadet.core.IComponent;
	import cadet.core.IRenderer;
	import cadet.events.ComponentEvent;
	import cadet.events.InvalidationEvent;
	import cadet.events.RendererEvent;
	import cadet.util.ComponentUtil;
	
	import cadet2D.components.renderers.IRenderer2D;
	import cadet2D.components.skins.IRenderable;
	
	import cadet2DFlash.components.skins.AbstractSkin2D;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class Renderer2D extends Component implements IRenderer2D
	{
		// Invalidation types
		protected static const VIEWPORT		:String = "viewport";
		
		// Container ID's
		public static const WORLD_CONTAINER					:String = "worldContainer";
		public static const VIEWPORT_BACKGROUND_CONTAINER	:String = "viewportBackgroundContainer";
		public static const VIEWPORT_FOREGROUND_CONTAINER	:String = "viewportForegroundContainer";
		
		// Config consts
		public static const NUM_CONTAINER_LAYERS			:int = 8;
		public static const NUM_VIEWPORT_FOREGROUND_LAYERS	:int = 8;
		public static const NUM_VIEWPORT_BACKGROUND_LAYERS	:int = 8;
		
		// Properties
		protected var _viewportWidth				:Number;
		protected var _viewportHeight				:Number;
		
		// Display Hierachy
		protected var _viewport							:Sprite;
		protected var _mask								:Shape;
			protected var viewportBackgroundContainer	:Sprite;
			protected var _worldContainer				:Sprite;
			protected var viewportForegroundContainer	:Sprite;
		
		protected var viewportBackgroundLayers			:Array;	
		protected var worldContainerLayers				:Array;
		protected var viewportForegroundLayers			:Array;	
		
		// Misc
		protected var skinTable				:Dictionary;
		protected var displayObjectTable	:Dictionary;
		protected var identityMatrix		:Matrix;
		protected var layersTable			:Object;
		
		private var _enabled				:Boolean;
		private var _initialised			:Boolean;
		private var _parent					:DisplayObjectContainer;
		
		public function Renderer2D()
		{
			name = "Renderer 2D";
			viewportWidth = 800;
			viewportHeight = 600;
			
			_viewport = new Sprite();
			
			_mask = new Shape();
			_viewport.addChild(_mask);
			_viewport.mask = _mask;
			
			viewportBackgroundContainer = new Sprite();
			_viewport.addChild(viewportBackgroundContainer);
			
			viewportBackgroundLayers = [];
			for ( var i:int = 0; i < NUM_VIEWPORT_BACKGROUND_LAYERS; i++ )
			{
				var layer:Sprite = new Sprite();
				viewportBackgroundLayers[i] = layer;
				viewportBackgroundContainer.addChild(layer);
			}
			
			_worldContainer = new Sprite();
			_viewport.addChild(_worldContainer);
			
			worldContainerLayers = [];
			for ( i = 0; i < NUM_CONTAINER_LAYERS; i++ )
			{
				layer = new Sprite();
				worldContainerLayers[i] = layer;
				_worldContainer.addChild(layer);
			}
			
			viewportForegroundContainer = new Sprite();
			_viewport.addChild(viewportForegroundContainer);
			
			viewportForegroundLayers = [];
			for ( i = 0; i < NUM_VIEWPORT_FOREGROUND_LAYERS; i++ )
			{
				layer = new Sprite();
				viewportForegroundLayers[i] = layer;
				viewportForegroundContainer.addChild(layer);
			}
			
			
			identityMatrix = new Matrix();
			skinTable = new Dictionary();
			displayObjectTable = new Dictionary();
			
			layersTable = {};
			layersTable[WORLD_CONTAINER] = worldContainerLayers;
			layersTable[VIEWPORT_BACKGROUND_CONTAINER] = viewportBackgroundLayers;
			layersTable[VIEWPORT_FOREGROUND_CONTAINER] = viewportForegroundLayers;
		}
		
		[Inspectable][Serializable]
		public function set viewportWidth( value:Number ):void
		{
			_viewportWidth = value;
			invalidate(VIEWPORT);
		}
		public function get viewportWidth():Number { return _viewportWidth; }
		
		[Inspectable][Serializable]
		public function set viewportHeight( value:Number ):void
		{
			_viewportHeight = value;
			invalidate(VIEWPORT);
		}
		public function get viewportHeight():Number { return _viewportHeight; }
		
		public function enable(parent:DisplayObjectContainer, depth:int = -1):void
		{
			_parent = parent;
			
			if (_enabled) return;
			
			if ( depth > -1 )	parent.addChildAt(viewport, depth);
			else				parent.addChild(viewport);
			
			_enabled = true;
			_initialised = true;
			
			dispatchEvent(new RendererEvent(RendererEvent.INITIALISED));
		}
		public function disable(parent:DisplayObjectContainer):void
		{
			_enabled = false;
			
			if ( parent.contains(viewport) ) {
				parent.removeChild(viewport);
			}
		}
		
		override public function validateNow():void
		{
			if ( isInvalid(VIEWPORT) )
			{
				validateViewport();
			}
			
			super.validateNow();
		}
		
		private function validateViewport():void
		{
			_mask.graphics.clear();
			_mask.graphics.beginFill(0xFF0000);
			_mask.graphics.drawRect(0,0,_viewportWidth,_viewportHeight);
		}
		
		public function getSkinForDisplayObject( displayObject:DisplayObject ):IRenderable
		{
			return displayObjectTable[displayObject];
		}
		
		override protected function addedToScene():void
		{
			scene.addEventListener(ComponentEvent.ADDED_TO_SCENE, componentAddedToSceneHandler);
			scene.addEventListener(ComponentEvent.REMOVED_FROM_SCENE, componentRemovedFromSceneHandler);
			
			var allSkins:Vector.<IComponent> = ComponentUtil.getChildrenOfType( scene, IRenderable, true );
			for each ( var skin:IRenderable in allSkins )
			{
				addSkin( skin );
			}
		}
		
		private function componentAddedToSceneHandler( event:ComponentEvent ):void
		{
			if ( event.component is IRenderable == false ) return;
			addSkin( IRenderable( event.component ) );
		}
		
		private function componentRemovedFromSceneHandler( event:ComponentEvent ):void
		{
			if ( event.component is IRenderable == false ) return;
			removeSkin( IRenderable( event.component ) );
		}
		
		private function addSkin( skin:IRenderable ):void
		{
			// Could be a Starling Skin of type ISkin2D
			if (!(skin is AbstractSkin2D)) return;
			
			addSkinToDisplayList(skin);
			
			var displayObject:DisplayObject = AbstractSkin2D(skin).displayObjectContainer;
			
			skin.addEventListener(InvalidationEvent.INVALIDATE, invalidateSkinHandler);
			skinTable[displayObject] = skin;
			displayObjectTable[displayObject] = skin;
		}
		
		private function removeSkin( skin:IRenderable ):void
		{
			// Could be a Starling Skin of type ISkin2D
			if (!(skin is AbstractSkin2D)) return;
			
			var displayObject:DisplayObject = AbstractSkin2D(skin).displayObjectContainer;
			
			removeSkinFromDisplayList(skin);
			skin.removeEventListener(InvalidationEvent.INVALIDATE, invalidateSkinHandler);
			delete skinTable[displayObject];
			delete displayObjectTable[displayObject];
		}
		
		private function invalidateSkinHandler( event:InvalidationEvent ):void
		{
			var skin:IRenderable = IRenderable(event.target);
			var displayObject:DisplayObject = AbstractSkin2D(skin).displayObjectContainer;
			
			if ( displayObject.parent == null )
			{
				addSkinToDisplayList(skin);
			}
			
			// The the layer index, or containerID on a ISkin2D has changed, then re-add them
			// to the displaylist at the appropritate place
			if ( event.invalidationType == "layer" || event.invalidationType == "container" )
			{
				addSkinToDisplayList(skin);
			}
		}
		
		private function addSkinToDisplayList( skin:IRenderable ):void
		{
			var layers:Array = layersTable[skin.containerID];
			if ( !layers ) return;
			
			var parent:DisplayObjectContainer = layers[skin.layerIndex];
			
			var displayObject:DisplayObject = AbstractSkin2D(skin).displayObjectContainer;
			
			parent.addChild( displayObject );
		}
		
		private function removeSkinFromDisplayList( skin:IRenderable ):void
		{
			var displayObject:DisplayObject = AbstractSkin2D(skin).displayObjectContainer;
			
			if ( displayObject.parent )
			{
				displayObject.parent.removeChild(displayObject);
			}
		}
		
		
		
		override protected function removedFromScene():void
		{
			super.removedFromScene();
			
			for each ( var layer:Sprite in worldContainerLayers )
			{
				while ( layer.numChildren > 0 )
				{
					var displayObject:DisplayObject = layer.getChildAt(0);
					var skin:IRenderable = skinTable[displayObject];
					layer.removeChildAt(0);
					delete skinTable[displayObject];
				}
			}
		}
		
		public function get viewport():Sprite { return _viewport; }
		public function get worldContainer():Sprite { return _worldContainer; }
		
		public function get mouseX():Number
		{
			return _viewport.mouseX;
		}
		public function get mouseY():Number
		{
			return _viewport.mouseY;
		}
		
		public function worldToViewport( pt:Point ):Point
		{
			pt = _worldContainer.localToGlobal(pt);
			return _viewport.globalToLocal(pt);
		}
		
		public function viewportToWorld( pt:Point ):Point
		{
			pt = _viewport.localToGlobal(pt);
			return _worldContainer.globalToLocal(pt);
		}
		
		public function setWorldContainerTransform( m:Matrix ):void
		{
			_worldContainer.transform.matrix = m;
		}
		
		public function getNativeStage():flash.display.Stage
		{
			return _parent.stage;
		}
		
		public function get initialised():Boolean
		{
			return _initialised;
		}
		
		//public function getWorldToViewportMatrix():Matrix { return identityMatrix.clone(); }
		//public function getViewportToWorldMatrix():Matrix { return identityMatrix.clone(); }
	}
}