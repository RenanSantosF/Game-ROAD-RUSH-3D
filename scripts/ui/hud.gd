class_name Hud
extends Control
## Interface durante a partida: moedas, distância, recorde, próxima meta,
## botão de pausa, avisos rápidos, contagem regressiva e dica inicial.
## Fica no topo da tela para não cobrir os obstáculos.

signal pause_pressed
signal countdown_finished

var _coins: CoinCounter
var _score: Label
var _best: Label
var _goal: Label
var _toast: Label
var _countdown: Label
var _tutorial: Label
var _fps: Label
var _pause: Button
var _toast_tween: Tween
var _countdown_tween: Tween
var _fps_timer := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var margin := UiTheme.make_safe_margin(get_viewport(), 18.0)
	add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	top.add_child(left)
	_coins = CoinCounter.new(34)
	_coins.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(_coins)
	_goal = UiTheme.make_label("", 22, Color(0.85, 0.95, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	left.add_child(_goal)

	var middle := VBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", -6)
	top.add_child(middle)
	_score = UiTheme.make_label("0 m", 60)
	middle.add_child(_score)
	_best = UiTheme.make_label("", 22, Color(0.85, 0.95, 1.0))
	middle.add_child(_best)

	var right := HBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(right)
	_pause = UiTheme.make_button("II", UiTheme.COLOR_NEUTRAL, Vector2(96, 96), 40)
	_pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_pause.pressed.connect(func(): pause_pressed.emit())
	right.add_child(_pause)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	_toast = UiTheme.make_label("", 40, UiTheme.COLOR_GOLD)
	_toast.modulate.a = 0.0
	column.add_child(_toast)
	column.add_child(UiTheme.spacer())
	_tutorial = UiTheme.make_label("Deslize para os LADOS para trocar de faixa\nPara CIMA para pular   |   Para BAIXO para deslizar", 28)
	_tutorial.visible = false
	column.add_child(_tutorial)
	_fps = UiTheme.make_label("", 20, Color(0.8, 1.0, 0.8), HORIZONTAL_ALIGNMENT_LEFT)
	_fps.visible = false
	column.add_child(_fps)

	_countdown = UiTheme.make_label("", 150, Color.WHITE)
	_countdown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown.visible = false
	add_child(_countdown)


func _process(delta: float) -> void:
	if _fps.visible:
		_fps_timer -= delta
		if _fps_timer <= 0.0:
			_fps_timer = 0.5
			_fps.text = "FPS: %d" % Engine.get_frames_per_second()


func reset(best: int) -> void:
	set_score(0)
	set_coins(0)
	_best.text = "Recorde: %d m" % best
	_toast.modulate.a = 0.0
	_countdown.visible = false
	set_pause_enabled(true)


func set_score(value: int) -> void:
	_score.text = "%d m" % value


func set_coins(value: int) -> void:
	_coins.set_value(value)


func set_goal(text: String) -> void:
	_goal.text = text


func set_pause_enabled(value: bool) -> void:
	_pause.visible = value


func set_fps_visible(value: bool) -> void:
	_fps.visible = value


func show_tutorial(value: bool) -> void:
	_tutorial.visible = value


func show_toast(text: String, color := UiTheme.COLOR_GOLD) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


## Contagem 3-2-1 antes de voltar ao jogo (funciona com o jogo pausado).
func start_countdown() -> void:
	set_pause_enabled(false)
	_countdown.visible = true
	if _countdown_tween != null:
		_countdown_tween.kill()
	_countdown_tween = create_tween()
	for n in [3, 2, 1]:
		_countdown_tween.tween_callback(_show_count.bind(str(n), "beep"))
		_countdown_tween.tween_interval(0.55)
	_countdown_tween.tween_callback(_finish_countdown)


func _show_count(text: String, sound: String) -> void:
	_countdown.text = text
	AudioManager.play_sfx(sound)


func _finish_countdown() -> void:
	_countdown.visible = false
	AudioManager.play_sfx("go")
	set_pause_enabled(true)
	countdown_finished.emit()


func is_counting_down() -> bool:
	return _countdown.visible
