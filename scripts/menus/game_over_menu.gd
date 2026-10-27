class_name GameOverMenu
extends BaseMenu
## Fim de partida: distância, recorde, moedas, missões concluídas e
## opção (anúncio recompensado) de dobrar as moedas da partida.

signal restart_pressed
signal menu_pressed
signal double_pressed

var _title: Label
var _score: Label
var _best: Label
var _coins: Label
var _missions: Label
var _double: Button


func _build() -> void:
	add_dim()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiTheme.make_panel()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	_title = UiTheme.make_label("", 50)
	col.add_child(_title)
	_score = UiTheme.make_label("", 64)
	col.add_child(_score)
	_best = UiTheme.make_label("", 26, Color(0.85, 0.95, 1.0))
	col.add_child(_best)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 10)
	col.add_child(coin_row)
	coin_row.add_child(CoinIcon.new(36))
	_coins = UiTheme.make_label("", 32, UiTheme.COLOR_GOLD)
	coin_row.add_child(_coins)
	_missions = UiTheme.make_label("", 22, Color(0.6, 1.0, 0.6))
	col.add_child(_missions)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	col.add_child(buttons)
	var menu := UiTheme.make_button("MENU", UiTheme.COLOR_NEUTRAL, Vector2(220, 88), 30)
	menu.pressed.connect(func(): menu_pressed.emit())
	buttons.add_child(menu)
	var again := UiTheme.make_button("JOGAR DE NOVO", UiTheme.COLOR_PRIMARY, Vector2(360, 88), 32)
	again.pressed.connect(func(): restart_pressed.emit())
	buttons.add_child(again)
	_double = UiTheme.make_button("", UiTheme.COLOR_ACCENT, Vector2(594, 72), 26)
	_double.pressed.connect(func(): double_pressed.emit())
	col.add_child(UiTheme.center(_double))


func show_results(score: int, best: int, coins: int, new_record: bool, completed: Array, can_double: bool) -> void:
	_title.text = "NOVO RECORDE!" if new_record else "FIM DE JOGO"
	_title.add_theme_color_override("font_color", UiTheme.COLOR_GOLD if new_record else Color.WHITE)
	_score.text = "%d pontos" % score
	_best.text = "Recorde: %d" % best
	_coins.text = "+%d moedas" % coins
	if completed.is_empty():
		_missions.text = ""
		_missions.visible = false
	else:
		_missions.visible = true
		_missions.text = "Missão concluída: " + ", ".join(PackedStringArray(completed))
	_double.text = "DOBRAR MOEDAS (assistir anúncio)"
	_double.disabled = false
	_double.visible = can_double and coins > 0
	open()


func mark_doubled(coins: int) -> void:
	_coins.text = "+%d moedas (dobrado!)" % (coins * 2)
	_double.disabled = true
	_double.text = "MOEDAS DOBRADAS"


func hide_double() -> void:
	_double.visible = false
