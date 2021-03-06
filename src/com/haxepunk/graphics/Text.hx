package com.haxepunk.graphics;

import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;

import com.haxepunk.HXP;
import com.haxepunk.Graphic;
import com.haxepunk.graphics.atlas.Atlas;
import com.haxepunk.graphics.atlas.AtlasRegion;

typedef TextOptions = {
	@:optional var font:String;
	@:optional var size:Int;
#if (flash || js)
	@:optional var align:TextFormatAlign;
#else
	@:optional var align:String;
#end
	@:optional var wordWrap:Bool;
	@:optional var resizable:Bool;
	@:optional var color:Int;
	@:optional var leading:Int;
};

/**
 * Used for drawing text using embedded fonts.
 */
class Text extends Image
{

	public var resizable:Bool;
	public var textWidth(default, null):Int;
	public var textHeight(default, null):Int;

	/**
	 * Constructor.
	 * @param text    Text to display.
	 * @param x       X offset.
	 * @param y       Y offset.
	 * @param width   Image width (leave as 0 to size to the starting text string).
	 * @param height  Image height (leave as 0 to size to the starting text string).
	 * @param options An object containing optional parameters contained in TextOptions
	 */
	public function new(text:String, x:Float = 0, y:Float = 0, width:Int = 0, height:Int = 0, ?options:TextOptions)
	{
		if (options == null)
		{
			options = {};
			options.color = 0xFFFFFF;
		}

		if (options.font == null)  options.font = HXP.defaultFont;
		if (options.size == 0)     options.size = 16;
		if (options.align == null) options.align = TextFormatAlign.LEFT;

		var fontObj = nme.Assets.getFont(options.font);
		_format = new TextFormat(fontObj.fontName, options.size, options.color);
		_format.align = options.align;
		_format.leading = options.leading;

		_field = new TextField();
#if flash
		_field.embedFonts = true;
#end
		_field.wordWrap = options.wordWrap;
		_field.defaultTextFormat = _format;
		_field.text = text;

		resizable = options.resizable;

		if (width == 0) width = Std.int(_field.textWidth + 4);
		if (height == 0) height = Std.int(_field.textHeight + 4);

		var source:Dynamic;
		if (HXP.renderMode.has(RenderMode.HARDWARE))
		{
			HXP.rect.x = HXP.rect.y = 0;
			HXP.rect.width = _field.width;
			HXP.rect.height = _field.height;
			source = new AtlasRegion(null, 0, HXP.rect);
		}
		else
		{
			source = HXP.createBitmap(width, height, true);
		}
		super(source);

		this.text = text;
		this.x = x;
		this.y = y;
	}

	/** @private Updates the drawing buffer. */
	public override function updateBuffer(clearBefore:Bool = false)
	{
		_field.setTextFormat(_format);

		if (_blit) _field.width = _bufferRect.width;
		_field.width = textWidth = Math.ceil(_field.textWidth + 4);
		_field.height = textHeight = Math.ceil(_field.textHeight + 4);

		if (_blit)
		{
			if (resizable)
			{
				_bufferRect.width = textWidth;
				_bufferRect.height = textHeight;
			}

			if (textWidth > _source.width || textHeight > _source.height)
			{
				_source = HXP.createBitmap(
					Std.int(Math.max(textWidth, _source.width)),
					Std.int(Math.max(textHeight, _source.height)),
					true);

				_sourceRect = _source.rect;
				createBuffer();
			}
			else
			{
				_source.fillRect(_sourceRect, HXP.blackColor);
			}

			if (resizable)
			{
				_field.width = textWidth;
				_field.height = textHeight;
			}

			_source.draw(_field);
			super.updateBuffer(clearBefore);
		}
	}

	public override function render(target:BitmapData, point:Point, camera:Point)
	{
		if (_blit)
		{
			super.render(target, point, camera);
		}
		else
		{
			_field.x = point.x + x - originX - camera.x * scrollX;
			_field.y = point.y + y - originY - camera.y * scrollY;
		}
	}

	/**
	 * Moves the TextField to the correct sprite layer
	 */
	private override function setLayer(value:Int):Int
	{
		if (value == layer) return value;
		if (_blit == false)
		{
			if (_parent != null)
			{
				_parent.removeChild(_field);
			}
			_parent = Atlas.getSpriteByLayer(value);
			_parent.addChild(_field);
		}
		return super.setLayer(value);
	}

	/**
	 * Text string.
	 */
	public var text(default, setText):String;
	private function setText(value:String):String
	{
		if (text == value) return value;
		_field.text = text = value;
		updateBuffer();
		return value;
	}

	/**
	 * Font family.
	 */
	public var font(default, setFont):String;
	private function setFont(value:String):String
	{
		if (font == value) return value;
#if nme
		value = nme.Assets.getFont(value).fontName;
#end
		_format.font = font = value;
		updateBuffer();
		return value;
	}

	/**
	 * Font size.
	 */
	public var size(default, setSize):Int;
	private function setSize(value:Int):Int
	{
		if (size == value) return value;
		_format.size = size = value;
		updateBuffer();
		return value;
	}

	// Text information.
	private var _field:TextField;
	private var _format:TextFormat;
	private var _parent:Sprite;
}