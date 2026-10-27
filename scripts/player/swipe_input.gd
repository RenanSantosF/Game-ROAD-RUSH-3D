class_name SwipeInput
extends Node
## Controles por toque:
## - Toque rápido: pula para a frente.
## - Deslizar para cima/baixo/esquerda/direita: pula nessa direção.
## O deslize dispara assim que o dedo percorre a distância mínima.
## Setas do teclado / WASD / espaço também funcionam (testes no PC).

signal swiped(direction: Vector2i)

## Distância mínima do deslize, em fração da altura da tela.
@export var min_distance_ratio := 0.05
## Toques mais longos que isso (segundos) não contam como toque rápido.
@export var max_tap_time := 0.35

var enabled := false

var _tracking := false
var _index := -1
var _start := Vector2.ZERO
var _start_time := 0
var _consumed := false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		_tracking = false
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not _tracking:
			_tracking = true
			_index = touch.index
			_start = touch.position
			_start_time = Time.get_ticks_msec()
			_consumed = false
		elif not touch.pressed and touch.index == _index:
			_tracking = false
			var quick := Time.get_ticks_msec() - _start_time <= int(max_tap_time * 1000.0)
			if not _consumed and quick:
				swiped.emit(Vector2i.UP)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _tracking or drag.index != _index or _consumed:
			return
		var delta := drag.position - _start
		var threshold := get_viewport().get_visible_rect().size.y * min_distance_ratio
		if delta.length() >= threshold:
			_consumed = true
			_emit_for(delta)
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_LEFT, KEY_A:
				swiped.emit(Vector2i.LEFT)
			KEY_RIGHT, KEY_D:
				swiped.emit(Vector2i.RIGHT)
			KEY_UP, KEY_W, KEY_SPACE:
				swiped.emit(Vector2i.UP)
			KEY_DOWN, KEY_S:
				swiped.emit(Vector2i.DOWN)


func _emit_for(delta: Vector2) -> void:
	if absf(delta.x) > absf(delta.y):
		swiped.emit(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
	else:
		swiped.emit(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)
