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
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	top.add_child(UiTheme.spacer(false))
	_coins = CoinCounter.new(34)
	top.add_child(_coins)

	var title := UiTheme.make_label("ROAD RUSH", 92, Color.WHITE)
	title.add_theme_constant_override("outline_size", 18)
	col.add_child(title)
	var sub := UiTheme.make_label("3D", 52, UiTheme.COLOR_GOLD)
	sub.add_theme_constant_override("outline_size", 12)
	col.add_child(sub)
	_best = UiTheme.make_label("", 30, Color(0.95, 1.0, 1.0))
	col.add_child(_best)

	col.add_child(UiTheme.spacer())

	var panel := UiTheme.make_panel()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_box(Color(0.06, 0.08, 0.15, 0.72)))
	col.add_child(panel)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	panel.add_child(buttons)
	var play := UiTheme.make_button(tr("MENU_PLAY"), UiTheme.COLOR_PRIMARY, Vector2(0, 116), 52)
	play.pressed.connect(func(): play_pressed.emit())
	buttons.add_child(play)
	var chars := UiTheme.make_button(tr("MENU_CHARACTERS"), UiTheme.COLOR_SECONDARY, Vector2(0, 84), 32)
	chars.pressed.connect(func(): characters_pressed.emit())
	buttons.add_child(chars)
	_missions_button = UiTheme.make_button(tr("MENU_MISSIONS"), UiTheme.COLOR_ACCENT, Vector2(0, 84), 32)
	_missions_button.pressed.connect(func(): missions_pressed.emit())
	buttons.add_child(_missions_button)
	var settings := UiTheme.make_button(tr("MENU_SETTINGS"), UiTheme.COLOR_NEUTRAL, Vector2(0, 84), 32)
	settings.pressed.connect(func(): settings_pressed.emit())
	buttons.add_child(settings)

	SaveManager.coins_changed.connect(func(total: int): _coins.set_value(total))
	Missions.missions_changed.connect(_refresh)


func _refresh() -> void:
	_coins.set_value(SaveManager.get_coins())
	_best.text = tr("BEST_POINTS") % SaveManager.get_best_score()
	_missions_button.text = tr("MENU_MISSIONS_ALERT") if Missions.has_claimable() else tr("MENU_MISSIONS")
