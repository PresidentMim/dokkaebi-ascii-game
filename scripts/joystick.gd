extends Control
## Mobile Legends style virtual joystick (bottom-left).
## Drag inside the circle to move. Works with touch and with the
## mouse on PC, so the game can be tested without a phone.
## game.gd reads `output` every frame (-1..1 on each axis).

var output: Vector2 = Vector2.ZERO

var _center: Vector2 = Vector2(110, 110)
var _radius: float = 82.0
var _knob_pos: Vector2 = Vector2(110, 110)
var _dragging: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(220, 220)
	mouse_filter = MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob_pos = _center
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		if not _dragging:
			_knob_pos = _center
		queue_redraw()


func _draw() -> void:
	draw_circle(_center, _radius, Color(1, 1, 1, 0.10))
	draw_arc(_center, _radius, 0.0, TAU, 64, Color(1, 1, 1, 0.35), 2.0)
	draw_circle(_knob_pos, 38.0, Color(1, 1, 1, 0.28))
	draw_circle(_knob_pos, 30.0, Color(0.25, 0.65, 0.35, 0.55))


func _update_from_local(local_pos: Vector2) -> void:
	var vec: Vector2 = local_pos - _center
	if vec.length() > _radius:
		vec = vec.normalized() * _radius
	_knob_pos = _center + vec
	output = vec / _radius
	queue_redraw()


func _reset() -> void:
	_dragging = false
	output = Vector2.ZERO
	_knob_pos = _center
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_dragging = true
			_update_from_local(touch.position)
		else:
			_reset()
	elif event is InputEventScreenDrag:
		if _dragging:
			_update_from_local((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_update_from_local(mb.position)
			else:
				_reset()
	elif event is InputEventMouseMotion:
		if _dragging:
			_update_from_local((event as InputEventMouseMotion).position)
