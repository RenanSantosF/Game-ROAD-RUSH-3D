class_name SwipeInput
extends Node
## Detecta gestos de deslizar (cima, baixo, esquerda, direita).
## O gesto dispara assim que o dedo percorre a distância mínima,
## sem esperar o dedo sair da tela. Toques curtos são ignorados.
## Setas do teclado / WASD também funcionam (testes no editor).

signal swiped(direction: Vector2i)

## Distância mínima do gesto, em fração da altura da tela.
@export var min_distance_ratio := 0.055

var enabled := false

var _tracking := false
var _index := -1
var _start := Vector2.ZERO
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
			_consumed = false
		elif not touch.pressed and touch.index == _index:
			_tracking = false
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
