package backend;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;

// PsychCamera handles followLerp based on elapsed
// and stops camera from snapping at higher framerates

class PsychCamera extends FlxCamera
{
	// Configuración para el movimiento de cámara en dirección de notas
	public var noteTweenDistance:Float = 30; // Distancia que se moverá la cámara
	public var noteTweenDuration:Float = 0.05; // Duración del tween en segundos
	public var noteTweenEase:EaseFunction = FlxEase.sineOut; // Función de ease para el tween
	public var noteMovementEnabled:Bool = false; // Activar/desactivar el movimiento de cámara con notas
	
	private var currentNoteTween:FlxTween = null;
	private var originalScrollTarget:FlxPoint = null;
	
	override public function update(elapsed:Float):Void
	{
		// follow the target, if there is one
		if (target != null)
		{
			updateFollowDelta(elapsed);
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		flashSprite.filters = filtersEnabled ? filters : null;

		updateFlashSpritePosition();
		updateShake(elapsed);


	}

	public function updateFollowDelta(?elapsed:Float = 0):Void
	{
		// Either follow the object closely,
		// or double check our deadzone and update accordingly.
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= viewRight)
				{
					_scrollTarget.x += viewWidth;
				}
				else if (targetX + target.width < viewLeft)
				{
					_scrollTarget.x -= viewWidth;
				}

				if (targetY >= viewBottom)
				{
					_scrollTarget.y += viewHeight;
				}
				else if (targetY + target.height < viewTop)
				{
					_scrollTarget.y -= viewHeight;
				}
				
				// without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
				bindScrollPos(_scrollTarget);
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				}
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
				{
					_scrollTarget.y = edge;
				}
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
				{
					_scrollTarget.y = edge;
				}
			}

			if ((target is FlxSprite))
			{
				if (_lastTargetPosition == null)
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
				}
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
		}

		var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1/60));
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
		//trace('lerp on this frame: $mult');
	}

	/**
	 * Mueve la cámara en la dirección de una nota cuando es presionada
	 * @param noteData El índice de la nota (0: izquierda, 1: abajo, 2: arriba, 3: derecha)
	 */
	/**
 * Apply a subtle camera offset for note hit.
 * @param noteData 0 = left, 1 = down, 2 = up, 3 = right
 * @param intensity How much the camera moves (lower = more subtle)
 */
public function moveOnNotePress(noteData:Int, intensity:Float = 10):Void
{
    if (!noteMovementEnabled) return;

    if (originalScrollTarget == null)
        originalScrollTarget = FlxPoint.get(_scrollTarget.x, _scrollTarget.y);

    var offsetX:Float = 0;
    var offsetY:Float = 0;

    switch(noteData)
    {
        case 0: offsetX = -intensity;
        case 1: offsetY = intensity;
        case 2: offsetY = -intensity;
        case 3: offsetX = intensity;
    }

    // Apply the offset to the scroll target
    _scrollTarget.x += offsetX;
    _scrollTarget.y += offsetY;

    // The camera will smoothly lerp back to the original position each frame
}

	
	/**
	 * Activa o desactiva el movimiento de cámara con notas
	 * @param enabled Si es true, activa el movimiento; si es false, lo desactiva
	 */
	public function setNoteMovementEnabled(enabled:Bool):Void
	{
		noteMovementEnabled = enabled;
	}
	
	/**
	 * Configura los parámetros del movimiento de cámara con notas
	 * @param distance Distancia que se moverá la cámara
	 * @param duration Duración del tween en segundos
	 * @param easeFunc Función de ease para el tween (opcional)
	 */
	public function configureNoteMovement(distance:Float, duration:Float, ?easeFunc:EaseFunction):Void
	{
		noteTweenDistance = distance;
		noteTweenDuration = duration;
		if (easeFunc != null) noteTweenEase = easeFunc;
	}

	override function set_followLerp(value:Float)
	{
		return followLerp = value;
	}
}