// Copyright (c) 2012, Unwrong Ltd. http://www.unwrong.com
// All rights reserved. 

// Draws the draggable circles on over the points in a polygon
// TODO: circle drawing currently looks like triangles.
package cadetEditor2DS.ui.overlays
{
	import flash.geom.Point;
	
	import cadet.events.ValidationEvent;
	
	import cadet2D.components.geom.PolygonGeometry;
	import cadet2D.components.transforms.Transform2D;
	import cadet2D.geom.Vertex;
	import cadet2D.overlays.Overlay;
	
	import cadetEditor2D.tools.ICadetEditorTool2D;
	
	import starling.core.RenderSupport;

	public class PolygonToolOverlay extends Overlay
	{
		private var tool		:ICadetEditorTool2D;
		private var _polygon	:PolygonGeometry;
		private var _transform	:Transform2D;
		
		private const CIRCLE_SIZE	:int = 5;
		
		public function PolygonToolOverlay( tool:ICadetEditorTool2D )
		{
			this.tool = tool;
		}
		
		public function set polygon( value:PolygonGeometry ):void
		{
			if ( _polygon )
			{
				_polygon.removeEventListener(ValidationEvent.INVALIDATE, invalidatePathHandler);
			}
			_polygon = value;
			if ( _polygon )
			{
				_polygon.addEventListener(ValidationEvent.INVALIDATE, invalidatePathHandler);
			}
			invalidate("*");
		}
		public function get polygon():PolygonGeometry { return _polygon; }
		
		public function set transform2D( value:Transform2D ):void
		{
			if ( _transform )
			{
				_transform.removeEventListener(ValidationEvent.INVALIDATE, invalidateTransformHandler);
			}
			_transform = value;
			if ( _transform )
			{
				_transform.addEventListener(ValidationEvent.INVALIDATE, invalidateTransformHandler);
			}
			invalidate("*");
		}
		public function get transform2D():Transform2D { return _transform; }
		
		private function invalidateTransformHandler( event:ValidationEvent ):void
		{
			invalidate("*");
		}
		
		private function invalidatePathHandler( event:ValidationEvent ):void
		{
			invalidate("*");
		}
		
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			super.render(support, parentAlpha);
			
			if ( isInvalid("*") )	validateNow();
		}
		
		override protected function validate():void
		{
			graphics.clear();
			
			if ( !_polygon ) return;
			if ( !_transform ) return;
			
			var L:int = _polygon.vertices.length;
			for ( var i:int = 0; i < L; i++ )
			{
				var vertex:Vertex = _polygon.vertices[i];
				
				var pt:Point = vertex.toPoint();
				pt = _transform.matrix.transformPoint(pt);
				pt = tool.view.renderer.worldToViewport(pt);
				
				graphics.beginFill(0xFFFFFF);
				graphics.drawCircle(pt.x, pt.y,CIRCLE_SIZE);
				graphics.endFill();
			}
		}

/*		public function get view():ICadetEditorView2D
		{
			return _view;
		}

		public function set view(value:ICadetEditorView2D):void
		{
			_view = value;
		}*/
	}
}