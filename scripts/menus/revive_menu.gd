class_name ReviveMenu
extends BaseMenu
## Oferta opcional para continuar a partida assistindo um anúncio
## recompensado. Some sozinha após alguns segundos.

signal revive_accepted
signal revive_declined

const OFFER_TIME := 6.0

var _bar: ProgressBar
var _time_left := 0.0
var _waiting_ad := false


func _build() -> void:
	add_dim()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiTheme.make_panel()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	col.add_child(UiTheme.make_label("CONTINUAR?", 54, UiTheme.COLOR_GOLD))
	col.add_child(UiTheme.make_label("Assista a um anúncio para continuar\nde onde parou (uma vez por partida).", 26))
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 18)
	_bar.show_percentage = false
	_bar.max_value = OFFER_TIME
	col.add_child(_bar)
	var watch := UiTheme.make_button("ASSISTIR E CONTINUAR", UiTheme.COLOR_PRIMARY, Vector2(460, 92), 32)
	watch.pressed.connect(_on_watch)
	col.add_child(UiTheme.center(watch))
	var skip := UiTheme.make_button("NÃO, OBRIGADO", UiTheme.COLOR_NEUTRAL, Vector2(460, 72), 26)
	skip.pressed.connect(_on_skip)
	col.add_child(UiTheme.center(skip))


func _refresh() -> void:
	_time_left = OFFER_TIME
	_waiting_ad = false
	_bar.value = OFFER_TIME


func _process(delta: float) -> void:
	if not visible or _waiting_ad:
		return
	_time_left -= delta
	_bar.value = _time_left
	if _time_left <= 0.0:
		_on_skip()


func _on_watch() -> void:
	if _waiting_ad:
		return
	_waiting_ad = true
	revive_accepted.emit()


func _on_skip() -> void:
	if not visible:
		return
	close()
	revive_declined.emit()
