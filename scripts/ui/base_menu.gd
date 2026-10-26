class_name BaseMenu
extends Control
## Base das telas: ocupa a tela toda, monta o conteúdo por código em
## _build() e aparece com uma animação curta de fade.

var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _build() -> void:
	pass


func _refresh() -> void:
	pass


func open() -> void:
	_refresh()
	visible = true
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)


func close() -> void:
	if _tween != null:
		_tween.kill()
	visible = false


func add_dim(color := UiTheme.COLOR_DIM) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	return bg


func add_safe_margin(base := 20.0) -> MarginContainer:
	var m := UiTheme.make_safe_margin(get_viewport(), base)
	add_child(m)
	return m
