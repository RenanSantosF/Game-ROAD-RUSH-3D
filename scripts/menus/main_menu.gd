class_name MainMenu
extends BaseMenu
## Menu inicial. O personagem aparece no cenário 3D ao lado do menu.

signal play_pressed
signal characters_pressed
signal missions_pressed
signal settings_pressed

var _coins: CoinCounter
var _best: Label
var _missions_button: Button


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := add_safe_margin(24.0)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var panel := UiTheme.make_panel()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Color(0.06, 0.08, 0.15, 0.72)))
	row.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var title := UiTheme.make_label("ROAD RUSH", 76, Color.WHITE)
	title.add_theme_constant_override("outline_size", 16)
	col.add_child(title)
	var sub := UiTheme.make_label("3D", 44, UiTheme.COLOR_GOLD)
	col.add_child(sub)
	_best = UiTheme.make_label("", 26, Color(0.85, 0.95, 1.0))
	col.add_child(_best)

	var play := UiTheme.make_button("JOGAR", UiTheme.COLOR_PRIMARY, Vector2(400, 104), 48)
	play.pressed.connect(func(): play_pressed.emit())
	col.add_child(play)
	var chars := UiTheme.make_button("PERSONAGENS", UiTheme.COLOR_SECONDARY, Vector2(400, 76), 30)
	chars.pressed.connect(func(): characters_pressed.emit())
	col.add_child(chars)
	_missions_button = UiTheme.make_button("MISSÕES", UiTheme.COLOR_ACCENT, Vector2(400, 76), 30)
	_missions_button.pressed.connect(func(): missions_pressed.emit())
	col.add_child(_missions_button)
	var settings := UiTheme.make_button("CONFIGURAÇÕES", UiTheme.COLOR_NEUTRAL, Vector2(400, 76), 30)
	settings.pressed.connect(func(): settings_pressed.emit())
	col.add_child(settings)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)
	_coins = CoinCounter.new(34)
	_coins.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(_coins)

	SaveManager.coins_changed.connect(func(total: int): _coins.set_value(total))
	Missions.missions_changed.connect(_refresh)


func _refresh() -> void:
	_coins.set_value(SaveManager.get_coins())
	_best.text = "Recorde: %d pontos" % SaveManager.get_best_score()
	_missions_button.text = "MISSÕES  (!)" if Missions.has_claimable() else "MISSÕES"
